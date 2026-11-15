import '../entities/password_reset_result.dart';
import '../repositories/password_reset_repository.dart';

/// Sets a new password using the emailed reset code.
///
/// The backend validates the code **before** the password strength, so a weak
/// password paired with a wrong code reports the code error. The server stays
/// authoritative on password rules.
///
/// Knows nothing about Dio, Flutter widgets, GetIt or storage.
class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final PasswordResetRepository _repository;

  Future<PasswordResetResult> call({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }
}
