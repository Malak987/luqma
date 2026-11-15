import '../entities/auth_session.dart';
import '../repositories/login_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final LoginRepository _repository;

  Future<AuthSession> call({
    required String email,
    required String password,
  }) {
    return _repository.login(
      email: email,
      password: password,
    );
  }
}
