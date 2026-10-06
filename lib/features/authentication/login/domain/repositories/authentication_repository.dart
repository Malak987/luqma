import '../entities/login_entity.dart';

abstract interface class AuthenticationRepository {
  Future<LoginEntity> login({
    required String usernameOrEmail,
    required String password,
  });
}
