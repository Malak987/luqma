import 'package:equatable/equatable.dart';

/// Outcome of a successful registration.
///
/// Deliberately **not** an `AuthSession`: Register returns no token, no user
/// id and no role. It only returns the backend's confirmation message, which
/// the UI shows before sending the user to email verification.
class RegisterResult extends Equatable {
  const RegisterResult({required this.message});

  final String message;

  @override
  List<Object> get props => <Object>[message];
}
