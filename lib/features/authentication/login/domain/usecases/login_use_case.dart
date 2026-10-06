import '../entities/login_entity.dart';
import '../repositories/authentication_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthenticationRepository _repository;

  Future<LoginEntity> call({
    required String usernameOrEmail,
    required String password,
  }) {
    return _repository.login(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );
  }
}
