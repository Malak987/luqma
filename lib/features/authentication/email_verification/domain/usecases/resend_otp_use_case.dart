import '../entities/email_verification_result.dart';
import '../repositories/email_verification_repository.dart';

/// Asks the backend to email a fresh OTP.
///
/// This must **never** be called automatically after Register: registration
/// already sends the first code, so an automatic resend would deliver two
/// emails. It is only ever triggered by an explicit user action.
class ResendOtpUseCase {
  const ResendOtpUseCase(this._repository);

  final EmailVerificationRepository _repository;

  Future<EmailVerificationResult> call({required String email}) {
    return _repository.resendOtp(email: email);
  }
}
