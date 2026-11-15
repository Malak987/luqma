import 'package:equatable/equatable.dart';

/// Outcome of a successful email confirmation or OTP resend.
///
/// Deliberately **not** an `AuthSession`. Neither endpoint is known to return
/// credentials, and confirming an email is not a sign-in, so nothing here can
/// be persisted as a session.
class EmailVerificationResult extends Equatable {
  const EmailVerificationResult({required this.message});

  /// The backend's Arabic confirmation text, shown to the user verbatim.
  final String message;

  @override
  List<Object> get props => <Object>[message];
}
