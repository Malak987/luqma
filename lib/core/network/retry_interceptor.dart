import 'dart:async';

import 'package:dio/dio.dart';

/// Retries requests that failed only because the backend was slow to wake up
/// (shared hosting puts idle apps to sleep, so the first call after a quiet
/// period often times out or gets a gateway error).
///
/// What is retried is deliberately narrow so a retry can never repeat a change:
/// * connection timeouts: the request never reached the server, any method;
/// * connection errors, receive/send timeouts and 502/503/504 answers: only
///   for GET/HEAD or requests explicitly marked idempotent (for example login).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 700),
  }) : _dio = dio;

  /// Set to `true` in `RequestOptions.extra` to opt a request out of retries.
  static const String disableKey = 'disableRetry';

  /// Set to `true` for non-GET requests that are safe to send twice.
  static const String idempotentKey = 'idempotentRequest';

  static const String _attemptKey = 'retryAttempt';

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (options.extra[disableKey] == true ||
        attempt >= maxRetries ||
        !_isRetryable(err)) {
      handler.next(err);
      return;
    }
    await Future<void>.delayed(baseDelay * (attempt + 1));
    options.extra[_attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  bool _isRetryable(DioException error) {
    final options = error.requestOptions;
    final method = options.method.toUpperCase();
    final safeToRepeat = method == 'GET' ||
        method == 'HEAD' ||
        options.extra[idempotentKey] == true;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return true;
      case DioExceptionType.connectionError:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return safeToRepeat;
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        return safeToRepeat && (code == 502 || code == 503 || code == 504);
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return false;
    }
  }
}
