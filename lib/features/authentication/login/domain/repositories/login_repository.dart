import '../entities/auth_session.dart';

abstract interface class LoginRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });
}
