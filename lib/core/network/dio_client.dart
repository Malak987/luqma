import 'package:dio/dio.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';

class DioClient {
  DioClient(this._secureStorageService) {
    _dio = Dio(
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
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  final SecureStorageService _secureStorageService;

  late final Dio _dio;

  Dio get dio => _dio;

  Future<void> _onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
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