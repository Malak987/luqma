import '../entities/email_verification_result.dart';
import '../repositories/email_verification_repository.dart';

/// Confirms a user's email with the OTP that was emailed to them.
///
/// Knows nothing about Dio, Flutter widgets, GetIt or storage.
class ConfirmEmailUseCase {
  const ConfirmEmailUseCase(this._repository);

  final EmailVerificationRepository _repository;

  Future<EmailVerificationResult> call({
    required String email,
    required String otp,
  }) {
    return _repository.confirmEmail(email: email, otp: otp);
  }
}
