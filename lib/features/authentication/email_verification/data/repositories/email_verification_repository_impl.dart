import '../../../../../core/error/failures.dart';
import '../../domain/entities/email_verification_result.dart';
import '../../domain/repositories/email_verification_repository.dart';
import '../datasources/email_verification_remote_data_source.dart';
import '../mappers/email_verification_mapper.dart';
import '../models/confirm_email_request_model.dart';
import '../models/resend_otp_request_model.dart';

/// Needs no `SecureStorageService`: confirming an email is not a sign-in and
/// neither endpoint is known to issue a token, so there is nothing to persist.
class EmailVerificationRepositoryImpl implements EmailVerificationRepository {
  const EmailVerificationRepositoryImpl(this._remoteDataSource);

  final EmailVerificationRemoteDataSource _remoteDataSource;

  @override
  Future<EmailVerificationResult> confirmEmail({
    required String email,
    required String otp,
  }) async {
    return _run(
      () => _remoteDataSource.confirmEmail(
        ConfirmEmailRequestModel(
          email: email.trim(),
          // The OTP is not trimmed: it is an opaque string and whitespace could
          // be significant to the backend comparison.
          otp: otp,
        ),
      ),
      'Confirm email',
    );
  }

  @override
  Future<EmailVerificationResult> resendOtp({required String email}) async {
    return _run(
      () => _remoteDataSource.resendOtp(
        ResendOtpRequestModel(email: email.trim()),
      ),
      'Resend verification code',
    );
  }

  Future<EmailVerificationResult> _run(
    Future<dynamic> Function() request,
    String operation,
  ) async {
    try {
      final responseModel = await request();
      return EmailVerificationMapper.toDomain(responseModel);
    } on RemoteException catch (error) {
      throw FailureException(
        Failure(
          error.code,
          debugMessage: error.message,
        ),
      );
    } on FailureException {
      rethrow;
    } catch (_) {
      // Never interpolate the raw error: it can contain the OTP.
      throw FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: '$operation could not be completed',
        ),
      );
    }
  }
}
