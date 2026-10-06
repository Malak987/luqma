import 'package:dio/dio.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';

class DioClient {
  DioClient(this._secureStorageService, {Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
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
