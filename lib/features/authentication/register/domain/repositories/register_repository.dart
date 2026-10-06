import '../entities/register_result.dart';

abstract interface class RegisterRepository {
  Future<RegisterResult> register({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String address,
  });
}
