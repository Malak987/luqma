import 'package:dio/dio.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/retry_interceptor.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';

class DioClient {
  DioClient(this._secureStorageService, {Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                // A sleeping host can take 20-40s to answer its first call:
                // connect fast (and retry), but let the response wait.
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 45),
                sendTimeout: const Duration(seconds: 20),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
    // Only for the real client: an injected Dio (tests, fakes) keeps exactly
    // the behaviour its caller configured.
    if (dio == null) {
      _dio.interceptors.add(RetryInterceptor(dio: _dio));
    }
  }

  /// Set this request extra to `true` only for protected endpoints.
  /// Requests without the flag are public and do not receive a stored token.
  static const String requiresAuthenticationExtraKey = 'requiresAuthentication';

  final SecureStorageService _secureStorageService;
  final Dio _dio;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuthentication =
        options.extra[requiresAuthenticationExtraKey] == true;

    if (!requiresAuthentication) {
      options.headers.removeWhere(
        (key, _) => key.toLowerCase() == 'authorization',
      );
      handler.next(options);
      return;
    }

    final token = await _secureStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  void _onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  void _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) {
    handler.next(error);
  }
}
