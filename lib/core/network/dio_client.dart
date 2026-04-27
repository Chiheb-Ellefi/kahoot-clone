import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../error/failures.dart';

/// Singleton Dio HTTP client with:
///  - Base URL configuration
///  - Request interceptor that injects the JWT Bearer token
///  - Response interceptor that maps HTTP errors to [Failure] types
class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor());

    return dio;
  }
}

/// Interceptor that:
///  1. Reads the stored JWT from [SharedPreferences] before every request
///  2. Attaches it as a `Bearer` Authorization header
///  3. Maps Dio errors to typed [Failure] exceptions on response errors
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // If prefs fail, proceed without the token
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    Failure failure;
    switch (statusCode) {
      case 400:
        final msg =
            err.response?.data?['message'] as String? ?? 'Invalid request.';
        failure = ValidationFailure(msg);
        break;
      case 401:
        failure = const UnauthorizedFailure();
        break;
      case 404:
        failure = const NotFoundFailure();
        break;
      case 409:
        final msg =
            err.response?.data?['message'] as String? ?? 'Conflict error.';
        failure = ConflictFailure(msg);
        break;
      case 500:
      default:
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError) {
          failure = const NetworkFailure(
            'Network error. Check your connection.',
          );
        } else if (statusCode != null) {
          failure = const ServerFailure();
        } else {
          failure = NetworkFailure(err.message ?? 'Unknown network error.');
        }
    }

    // Wrap failure as a DioException carrying the Failure in its `error` field
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: failure,
        message: failure.message,
        type: err.type,
      ),
    );
  }
}

/// Helper to extract a [Failure] from a [DioException].
Failure dioErrorToFailure(DioException e) {
  if (e.error is Failure) return e.error as Failure;
  return ServerFailure(e.message ?? 'Unknown error.');
}
