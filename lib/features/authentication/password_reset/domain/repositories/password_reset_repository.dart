import '../entities/password_reset_result.dart';

abstract interface class PasswordResetRepository {
  /// Asks the backend to email a reset code. There is no separate resend
  /// endpoint, so calling this again **is** the resend.
  Future<PasswordResetResult> forgotPassword({required String email});

  Future<PasswordResetResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}
