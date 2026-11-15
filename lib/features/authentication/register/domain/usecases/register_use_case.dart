import '../entities/register_result.dart';
import '../repositories/register_repository.dart';

/// Application-level Register operation.
///
/// Knows nothing about Dio, Flutter widgets, GetIt or storage; it only
/// forwards to the repository abstraction.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final RegisterRepository _repository;

  Future<RegisterResult> call({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String address,
  }) {
    return _repository.register(
      userName: userName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      phoneNumber: phoneNumber,
      address: address,
    );
  }
}
