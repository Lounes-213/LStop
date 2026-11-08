import 'package:dio/dio.dart';
import '../auth/secure_token_storage.dart';
import '../utils/result.dart';
import '../utils/app_logger.dart';
import 'auth_interceptor.dart';
import '../constants/app_constants.dart';

class ApiClient {
  final Dio _dio;
  final SecureTokenStorage tokenStorage;
  final String baseUrl;

  ApiClient({
    String? baseUrl,
    SecureTokenStorage? tokenStorage,
  })  : baseUrl = baseUrl ?? AppConstants.defaultApiBaseUrl,
        tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? AppConstants.defaultApiBaseUrl,
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      AuthInterceptor(
        dio: _dio,
        tokenStorage: this.tokenStorage,
        baseUrl: this.baseUrl,
      ),
    );
  }

  Dio get dio => _dio;

  Future<Result<T, String>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      final parsed = parser != null ? parser(response.data) : response.data as T;
      return Success(parsed);
    } on DioException catch (e) {
      AppLogger.e('GET $path failed', e);
      return Failure(_extractErrorMessage(e));
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<T, String>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic data)? parser,
  }) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      final parsed = parser != null ? parser(response.data) : response.data as T;
      return Success(parsed);
    } on DioException catch (e) {
      AppLogger.e('POST $path failed', e);
      return Failure(_extractErrorMessage(e));
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<T, String>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(_extractErrorMessage(e));
    } catch (e) {
      return Failure(e.toString());
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map && e.response?.data['error'] != null) {
      return e.response?.data['error'].toString() ?? 'Une erreur est survenue';
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout => 'Délai de connexion dépassé. Vérifiez votre réseau.',
      DioExceptionType.receiveTimeout => 'Le serveur met trop de temps à répondre.',
      DioExceptionType.badResponse => 'Erreur du serveur (${e.response?.statusCode})',
      _ => 'Problème de connexion internet',
    };
  }
}
