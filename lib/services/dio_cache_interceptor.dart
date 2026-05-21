import 'package:dio/dio.dart';

class CacheEntry {
  final Response response;
  final DateTime expiresAt;

  CacheEntry(this.response, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DioCacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final key = _buildCacheKey(options);
    final cached = _cache[key];

    if (cached != null) {
      if (!cached.isExpired) {
        // Return a fresh copy of the cached response with current RequestOptions
        final response = Response(
          requestOptions: options,
          data: cached.response.data,
          headers: cached.response.headers,
          isRedirect: cached.response.isRedirect,
          redirects: cached.response.redirects,
          extra: cached.response.extra,
          statusCode: cached.response.statusCode,
          statusMessage: cached.response.statusMessage,
        );
        return handler.resolve(response);
      } else {
        // Evict expired cache entry
        _cache.remove(key);
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Only cache GET requests
    if (response.requestOptions.method.toUpperCase() != 'GET') {
      return handler.next(response);
    }

    final path = response.requestOptions.path;
    Duration? ttl;

    if (path.startsWith('/articles')) {
      ttl = const Duration(minutes: 5);
    } else if (path.startsWith('/regions')) {
      ttl = const Duration(minutes: 30);
    }

    if (ttl != null) {
      final key = _buildCacheKey(response.requestOptions);
      final expiresAt = DateTime.now().add(ttl);
      _cache[key] = CacheEntry(response, expiresAt);
    }

    handler.next(response);
  }

  /// Invalidates cache entries matching the given path prefix
  void invalidate(String pathPrefix) {
    final cleanPath = pathPrefix.startsWith('/') ? pathPrefix : '/$pathPrefix';
    _cache.removeWhere((key, entry) {
      return key.startsWith(cleanPath) || key.contains(cleanPath);
    });
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
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return '${options.path}?$queryStr';
  }
}
