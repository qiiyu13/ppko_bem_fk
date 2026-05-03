import 'package:dio/dio.dart';
import '../config/env.dart';
import '../exceptions/sync_conflict_exception.dart';
import 'token_service.dart';

class ApiService {
  static const String baseUrl = Env.apiBaseUrl;

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static void setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final currentToken = await TokenService.getToken();
              if (currentToken != null) {
                final refreshResponse = await Dio().post(
                  '$baseUrl/auth/refresh',
                  options: Options(headers: {'Authorization': 'Bearer $currentToken'}),
                );
                final newToken = refreshResponse.data['data']['token'];
                await TokenService.setToken(newToken);
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final retryResponse = await Dio().fetch(opts);
                handler.resolve(retryResponse);
                return;
              }
            } catch (refreshError) {
              await TokenService.clearAll();
            }
          }
          if (error.response?.statusCode == 409) {
            final serverData =
                error.response?.data['data'] as Map<String, dynamic>? ?? {};
            final localData =
                error.requestOptions.data as Map<String, dynamic>? ?? {};
            throw SyncConflictException(
              message:
                  error.response?.data['error']?['message'] ??
                  'Data conflict detected',
              serverData: serverData,
              localData: localData,
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => dio.get(path, queryParameters: queryParameters);

  static Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  static Future<Response> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  static Future<Response> delete(String path, {dynamic data}) =>
      dio.delete(path, data: data);

  static Future<Response> request(
    String method,
    String path, {
    dynamic data,
  }) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return get(path);
      case 'POST':
        return post(path, data: data);
      case 'PUT':
        return put(path, data: data);
      case 'DELETE':
        return delete(path, data: data);
      default:
        throw Exception('Unsupported method: $method');
    }
  }
}
