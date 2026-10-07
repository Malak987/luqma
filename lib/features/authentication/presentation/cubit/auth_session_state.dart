import 'package:equatable/equatable.dart';

enum AuthSessionStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
}

class AuthSessionState extends Equatable {
  const AuthSessionState({
    required this.status,
  });

  const AuthSessionState.initial()
      : status = AuthSessionStatus.initial;

  const AuthSessionState.checking()
      : status = AuthSessionStatus.checking;

  const AuthSessionState.authenticated()
      : status = AuthSessionStatus.authenticated;

  const AuthSessionState.unauthenticated()
      : status = AuthSessionStatus.unauthenticated;

  final AuthSessionStatus status;

  bool get isAuthenticated =>
      status == AuthSessionStatus.authenticated;

  @override
  List<Object> get props => <Object>[status];
}
