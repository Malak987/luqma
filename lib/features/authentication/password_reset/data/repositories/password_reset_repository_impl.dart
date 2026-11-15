import '../../../../../core/error/failures.dart';
import '../../domain/entities/password_reset_result.dart';
import '../../domain/repositories/password_reset_repository.dart';
import '../datasources/password_reset_remote_data_source.dart';
import '../mappers/password_reset_mapper.dart';
import '../models/forgot_password_request_model.dart';
import '../models/reset_password_request_model.dart';

/// Needs no `SecureStorageService`: resetting a password is not a sign-in and
/// neither endpoint is known to issue a token, so there is nothing to persist.
class PasswordResetRepositoryImpl implements PasswordResetRepository {
  const PasswordResetRepositoryImpl(this._remoteDataSource);

  final PasswordResetRemoteDataSource _remoteDataSource;

  @override
  Future<PasswordResetResult> forgotPassword({required String email}) async {
    return _run(
      () => _remoteDataSource.forgotPassword(
        ForgotPasswordRequestModel(email: email.trim()),
      ),
      'Forgot password',
    );
  }

  @override
  Future<PasswordResetResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return _run(
      () => _remoteDataSource.resetPassword(
        ResetPasswordRequestModel(
          email: email.trim(),
          // Neither secret is trimmed: both are opaque strings and whitespace
          // could be significant to the backend comparison.
          otp: otp,
          newPassword: newPassword,
        ),
      ),
      'Reset password',
    );
  }

  Future<PasswordResetResult> _run(
    Future<dynamic> Function() request,
    String operation,
  ) async {
    try {
      final responseModel = await request();
      return PasswordResetMapper.toDomain(responseModel);
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
      // Never interpolate the raw error: it can contain the OTP or password.
      throw FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: '$operation could not be completed',
        ),
      );
    }
  }
}
