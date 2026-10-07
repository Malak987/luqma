import '../entities/email_verification_result.dart';

abstract interface class EmailVerificationRepository {
  Future<EmailVerificationResult> confirmEmail({
    required String email,
    required String otp,
  });

  Future<EmailVerificationResult> resendOtp({required String email});
}
