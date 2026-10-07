import 'package:dio/dio.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../models/confirm_email_request_model.dart';
import '../models/email_verification_envelope_model.dart';
import '../models/email_verification_failure_parser.dart';
import '../models/email_verification_response_model.dart';
import '../models/resend_otp_request_model.dart';

abstract interface class EmailVerificationRemoteDataSource {
  Future<EmailVerificationResponseModel> confirmEmail(
    ConfirmEmailRequestModel request,
  );

  Future<EmailVerificationResponseModel> resendOtp(
    ResendOtpRequestModel request,
  );
}

class EmailVerificationRemoteDataSourceImpl
    implements EmailVerificationRemoteDataSource {
  const EmailVerificationRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<EmailVerificationResponseModel> confirmEmail(
    ConfirmEmailRequestModel request,
  ) {
    return _post(
      ApiConstants.confirmEmail,
      request.toJson(),
      'Confirm email',
    );
  }

  @override
  Future<EmailVerificationResponseModel> resendOtp(
    ResendOtpRequestModel request,
  ) {
    return _post(
      ApiConstants.resendOtp,
      request.toJson(),
      'Resend verification code',
    );
  }

  Future<EmailVerificationResponseModel> _post(
    String path,
    Map<String, dynamic> body,
    String operation,
  ) async {
    try {
      final response = await _dioClient.dio.post<Object?>(
        path,
        data: body,
        // Both verification endpoints are anonymous. Swagger declares a global
        // bearer scheme, but the backend does not enforce it — sending a token
        // would be wrong and could leak a stale one, so the flag is explicit.
        options: Options(
          extra: <String, dynamic>{
            DioClient.requiresAuthenticationExtraKey: false,
          },
        ),
      );

      final envelope = EmailVerificationEnvelopeModel.fromJson(
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
        // message in the body ("رمز التحقق غير صحيح أو منتهي الصلاحية",
        // "المستخدم غير موجود", ...). That message is the only description of
        // the failure, so it is recovered and shown to the user.
        final message = EmailVerificationFailureParser.parse(
          error.response?.data,
        );
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
      // Covers an invalid/expired OTP and an unknown account. No new
      // FailureCode is introduced; the existing validation code is reused.
      return FailureCode.validation;
    }
    if (statusCode == 401 || statusCode == 403) {
      return FailureCode.invalidCredentials;
    }
    return FailureCode.unknown;
  }
}
