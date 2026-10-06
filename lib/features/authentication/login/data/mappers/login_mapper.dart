import '../../domain/entities/auth_session.dart';
import '../models/login_response_model.dart';

abstract final class LoginMapper {
  static AuthSession toDomain(LoginResponseModel model) {
    return AuthSession(
      userId: model.userId,
      userName: model.userName,
      role: model.role,
      token: model.token,
      expiresAt: model.expiresAt,
    );
  }
}
