import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({
    required this.userId,
    required this.userName,
    required this.role,
    required this.token,
    required this.expiresAt,
  });

  final String userId;
  final String userName;
  final String role;
  final String token;
  final DateTime expiresAt;

  @override
  List<Object> get props => <Object>[
        userId,
        userName,
        role,
        token,
        expiresAt,
      ];

  // AuthSession equality includes the token, but its string representation must
  // never disclose it in diagnostics or logs.
  @override
  bool get stringify => false;
}
