import '../../domain/entities/login_entity.dart';

class LoginModel extends LoginEntity {
  const LoginModel({
    required super.userId,
    required super.username,
    required super.token,
    required super.role,
    required super.expiresAt,
  });

  factory LoginModel.fromMap(Map<String, dynamic> map) {
    return LoginModel(
      userId: map['userId'] as String? ?? '',
      username: map['userName'] as String? ??
          map['username'] as String? ??
          '',
      token: map['token'] as String? ?? '',
      role: map['role'] as String? ?? '',
      expiresAt: map['expiresAt'] as String? ?? '',
    );
  }
}