import '../entities/password_reset_result.dart';
import '../repositories/password_reset_repository.dart';

/// Asks the backend to email a password-reset code.
///
/// This is also the only way to request **another** code: the API has no
/// dedicated resend endpoint, so the Reset screen calls this again with the
/// same email.
///
/// Knows nothing about Dio, Flutter widgets, GetIt or storage.
class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final PasswordResetRepository _repository;

  Future<PasswordResetResult> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}
