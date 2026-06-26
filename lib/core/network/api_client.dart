import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:padbro/core/errors/exceptions.dart';
import 'package:padbro/core/network/api_endpoints.dart';

/// API Client for making HTTP requests
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  ApiClient({
    required FlutterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(secureStorage: _secureStorage));
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// POST request with multipart form data (for file uploads)
  Future<Response> postMultipart(
    String path, {
    required FormData data,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Handle Dio exceptions and convert to custom exceptions
  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        // Handle validation errors (422)
        if (statusCode == 422) {
          final errors = data['errors'] as Map<String, dynamic>?;
          final message = data['message'] as String? ?? 'Validation failed';
          return ValidationException(
            message: message,
            errors: errors?.map(
              (key, value) => MapEntry(
                key,
                (value as List).map((e) => e.toString()).toList(),
              ),
            ),
          );
        }

        // Handle authentication errors (401)
        if (statusCode == 401) {
          final message = data['message'] as String? ?? 'Authentication failed';
          return AuthException(message: message);
        }

        // Handle other server errors
        final message = data['message'] as String? ?? 'Server error occurred';
        return ServerException(
          message: message,
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const ServerException(message: 'Request cancelled');

      case DioExceptionType.unknown:
      default:
        if (e.error != null && e.error.toString().contains('SocketException')) {
          return const NetworkException(
            message: 'No internet connection. Please check your network.',
          );
        }
        return ServerException(
          message: e.message ?? 'An unexpected error occurred',
        );
    }
  }
}

/// Interceptor for adding auth token to requests
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  static const String _tokenKey = 'auth_token';

  _AuthInterceptor({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available
    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 errors (token expired) - could trigger logout here
    if (err.response?.statusCode == 401) {
      // Could emit an event to logout the user
    }
    handler.next(err);
  }
}

