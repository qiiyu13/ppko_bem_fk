import 'dart:convert';
import 'package:dio/dio.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class CacheEntry {
  final Response response;
  final DateTime expiresAt;

  CacheEntry(this.response, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DioCacheInterceptor extends Interceptor {
  // L1: in-memory, instant. L2: CacheService (sqlite), survives app restart.
  final Map<String, CacheEntry> _cache = {};

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final key = _buildCacheKey(options);
    final mem = _cache[key];

    // Fresh in-memory hit — serve instantly, no disk, no network.
    if (mem != null && !mem.isExpired) {
      return handler.resolve(_copy(mem.response, options));
    }

    // Offline: don't burn the full timeout waiting for a request that can't
    // succeed. Serve whatever we have (stale is fine) so the UI never blanks.
    if (!ConnectivityService.instance.isOnline) {
      final cached = await _readAnyCache(key, options);
      if (cached != null) return handler.resolve(cached);
      // Nothing cached — fall through so the request fails fast.
    } else if (mem != null) {
      _cache.remove(key); // expired; let the network refresh it
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // A successful mutation invalidates every cached read for that resource
    // immediately — don't wait for the WebSocket round-trip, so the next GET
    // after a create/update/delete never serves stale data. Invalidate by the
    // root segment ('/profiles/123' -> '/profiles') to also clear list caches.
    if (response.requestOptions.method.toUpperCase() != 'GET') {
      final segments = response.requestOptions.path.split('/')
        ..removeWhere((s) => s.isEmpty);
      if (segments.isNotEmpty) invalidate('/${segments.first}');
      return handler.next(response);
    }

    final ttl = _ttlFor(response.requestOptions.path);
    if (ttl != null) {
      final key = _buildCacheKey(response.requestOptions);
      final expiresAt = DateTime.now().add(ttl);
      _cache[key] = CacheEntry(response, expiresAt);
      _persist(key, response, expiresAt); // fire-and-forget disk write
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Stale-if-error: on a network/timeout failure (not an HTTP error response
    // like 401/409), serve the last cached value so a flaky connection degrades
    // to "slightly stale" instead of "broken".
    const networkFailures = {
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    };
    if (networkFailures.contains(err.type) &&
        err.requestOptions.method.toUpperCase() == 'GET') {
      final key = _buildCacheKey(err.requestOptions);
      final cached = await _readAnyCache(key, err.requestOptions);
      if (cached != null) return handler.resolve(cached);
    }
    handler.next(err);
  }

  /// Invalidates cache entries matching the given path prefix (memory + disk).
  void invalidate(String pathPrefix) {
    final cleanPath = pathPrefix.startsWith('/') ? pathPrefix : '/$pathPrefix';
    _cache.removeWhere((key, entry) {
      return key.startsWith(cleanPath) || key.contains(cleanPath);
    });
    CacheService.invalidateHttpCache(cleanPath);
  }

  /// Clears the entire in-memory cache. Called on logout so stale data from the
  /// previous session is never served to a newly logged-in account.
  void clearAll() {
    _cache.clear();
  }

  // Reads any cached value (in-memory first, then disk), even if expired.
  Future<Response?> _readAnyCache(String key, RequestOptions options) async {
    final mem = _cache[key];
    if (mem != null) return _copy(mem.response, options);

    final disk = await CacheService.getHttpCache(key);
    if (disk != null) {
      return Response(
        requestOptions: options,
        data: jsonDecode(disk['body'] as String),
        statusCode: disk['status'] as int? ?? 200,
        extra: const {'fromCache': true},
      );
    }
    return null;
  }

  void _persist(String key, Response response, DateTime expiresAt) {
    try {
      CacheService.saveHttpCache(
        key,
        jsonEncode(response.data),
        response.statusCode ?? 200,
        expiresAt,
      );
    } catch (_) {
      // Non-JSON-serializable body — skip disk persistence, keep memory cache.
    }
  }

  Response _copy(Response cached, RequestOptions options) {
    return Response(
      requestOptions: options,
      data: cached.data,
      headers: cached.headers,
      isRedirect: cached.isRedirect,
      redirects: cached.redirects,
      extra: cached.extra,
      statusCode: cached.statusCode,
      statusMessage: cached.statusMessage,
    );
  }

  // TTLs are a fallback ceiling; the WebSocket data:update event invalidates
  // these prefixes the moment the underlying data changes, so the cache stays
  // correct in real time and the TTL only bounds staleness when offline.
  Duration? _ttlFor(String path) {
    if (path.startsWith('/articles')) return const Duration(minutes: 5);
    if (path.startsWith('/regions')) return const Duration(minutes: 30);
    if (path.startsWith('/profiles')) return const Duration(minutes: 10);
    if (path.startsWith('/appointments')) return const Duration(minutes: 5);
    if (path.startsWith('/metrics')) return const Duration(minutes: 5);
    return null;
  }

  /// Builds a unique cache key based on path and query parameters
  String _buildCacheKey(RequestOptions options) {
    if (options.queryParameters.isEmpty) {
      return options.path;
    }
    final sortedParams = Map.fromEntries(
      options.queryParameters.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    final queryStr = sortedParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return '${options.path}?$queryStr';
  }
}
