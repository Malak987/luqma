import 'package:equatable/equatable.dart';

class LoginEntity extends Equatable {
  const LoginEntity({
    required this.userId,
    required this.username,
    required this.token,
    required this.role,
    required this.expiresAt,
  });

  final String userId;
  final String username;
  final String token;
  final String role;
  final String expiresAt;

  @override
  List<Object> get props => <Object>[
        userId,
        username,
        token,
        role,
        expiresAt,
      ];
}
