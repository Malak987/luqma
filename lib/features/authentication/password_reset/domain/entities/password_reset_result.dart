import 'package:equatable/equatable.dart';

/// Outcome of a successful reset-code request or password reset.
///
/// Deliberately **not** an `AuthSession`. Neither endpoint is known to return
/// credentials, and resetting a password is not a sign-in, so nothing here can
/// be persisted as a session.
class PasswordResetResult extends Equatable {
  const PasswordResetResult({required this.message});

  /// The backend's Arabic text, shown to the user verbatim.
  final String message;

  @override
  List<Object> get props => <Object>[message];
}
