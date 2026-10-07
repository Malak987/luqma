import 'package:dio/dio.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../models/forgot_password_request_model.dart';
import '../models/password_reset_envelope_model.dart';
import '../models/password_reset_failure_parser.dart';
import '../models/password_reset_response_model.dart';
import '../models/reset_password_request_model.dart';

abstract interface class PasswordResetRemoteDataSource {
  Future<PasswordResetResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  );

  Future<PasswordResetResponseModel> resetPassword(
    ResetPasswordRequestModel request,
  );
}

class PasswordResetRemoteDataSourceImpl implements PasswordResetRemoteDataSource {
  const PasswordResetRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<PasswordResetResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  ) {
    return _post(
      ApiConstants.forgotPassword,
      request.toJson(),
      'Forgot password',
    );
  }

  @override
  Future<PasswordResetResponseModel> resetPassword(
    ResetPasswordRequestModel request,
  ) {
    return _post(
      ApiConstants.resetPassword,
      request.toJson(),
      'Reset password',
    );
  }

  Future<PasswordResetResponseModel> _post(
    String path,
    Map<String, dynamic> body,
    String operation,
  ) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        path,
        data: body,
        // Both password-reset endpoints are anonymous. Swagger declares a
        // global bearer scheme, but the backend does not enforce it — sending a
        // token would be wrong and could leak a stale one, so the flag is set
        // explicitly and DioClient strips any Authorization header.
        options: Options(
          extra: <String, dynamic>{
            DioClient.requiresAuthenticationExtraKey: false,
          },
        ),
      );

      final envelope = PasswordResetEnvelopeModel.fromJson(
        response.data,
        description: '$operation response envelope',
      );

      // Defensive: a 200 that still reports failure has not been observed,
      // but the envelope carries the flag so it is honoured if it happens.
      if (!envelope.isSucceeded || envelope.data == null) {
        throw RemoteException(
          code: FailureCode.validation,
          message: envelope.message ?? '$operation request was not successful',
        );
      }

      return envelope.data!;
    } on DioException catch (error) {
      throw _mapDioException(error, operation);
    } on RemoteException {
      rethrow;
    } on FormatException {
      throw RemoteException(
        code: FailureCode.unknown,
        message: 'Invalid $operation response',
      );
    }
  }

  RemoteException _mapDioException(DioException error, String operation) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const RemoteException(
          code: FailureCode.network,
          message: 'Network request failed',
        );

      case DioExceptionType.badResponse:
        // The backend answers every rejection with HTTP 400 and an Arabic
        // message in the body ("البريد الإلكتروني غير موجود",
        // "رمز التحقق غير صحيح أو منتهي الصلاحية", ...). That message is the
        // only description of the failure, so it is recovered and shown.
        final message = PasswordResetFailureParser.parse(error.response?.data);
        return RemoteException(
          code: _codeForStatusCode(error.response?.statusCode),
          message: message ?? '$operation request failed',
        );

      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return RemoteException(
          code: FailureCode.unknown,
          message: '$operation request failed',
        );
    }
  }

  FailureCode _codeForStatusCode(int? statusCode) {
    if (statusCode == 400) {
      // Covers an unknown email, an invalid/expired OTP and a rejected
      // password. No new FailureCode is introduced; the existing validation
      // code is reused, consistent with the other public auth flows.
      return FailureCode.validation;
    }
    if (statusCode == 401 || statusCode == 403) {
      return FailureCode.invalidCredentials;
    }
    return FailureCode.unknown;
  }
}
