/// Payload for `POST /api/Account/ForgotPassword`.
///
/// The backend identifies the account by email address only. This single
/// endpoint is also the mechanism for asking for **another** reset code: there
/// is no separate resend endpoint, so a repeat call is a resend.
final class ForgotPasswordRequestModel {
  const ForgotPasswordRequestModel({required this.email});

  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
      };
}
