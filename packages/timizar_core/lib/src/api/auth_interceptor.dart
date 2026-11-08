import 'dart:async';
import 'package:dio/dio.dart';
import '../auth/secure_token_storage.dart';
import '../auth/auth_token.dart';
import 'api_endpoints.dart';
import '../utils/app_logger.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SecureTokenStorage tokenStorage;
  final String baseUrl;
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _failedQueue = [];

  AuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    required this.baseUrl,
  });

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for login or refresh endpoints
    if (options.path.contains(ApiEndpoints.googleLogin) ||
        options.path.contains(ApiEndpoints.refreshToken)) {
      return handler.next(options);
    }

    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;

    // Only handle 401 Unauthorized
    if (response?.statusCode != 401 ||
        err.requestOptions.path.contains(ApiEndpoints.googleLogin) ||
        err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
      return handler.next(err);
    }

    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      _failedQueue.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;

    try {
      AppLogger.i('Access token expired (401). Attempting refresh...');

      // Make refresh call using a clean Dio instance to avoid interceptor recursion
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      final refreshRes = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (refreshRes.statusCode == 200 && refreshRes.data != null) {
        final newTokens = AuthTokens.fromJson(refreshRes.data as Map<String, dynamic>);
        await tokenStorage.saveTokens(newTokens);
        AppLogger.i('Token refreshed successfully');

        // Retry current request
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
        final retryResponse = await dio.fetch(retryOptions);
        handler.resolve(retryResponse);

        // Process queued failed requests
        for (final item in _failedQueue) {
          item.options.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
          final queuedRes = await dio.fetch(item.options);
          item.handler.resolve(queuedRes);
        }
        _failedQueue.clear();
      } else {
        await tokenStorage.clearAll();
        handler.next(err);
      }
    } catch (e) {
      AppLogger.e('Failed to refresh token: $e');
      await tokenStorage.clearAll();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
