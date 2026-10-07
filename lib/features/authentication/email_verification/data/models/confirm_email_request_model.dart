/// Payload for `POST /api/Account/ConfirmEmail`.
///
/// The backend identifies the account by **email address only** — there is no
/// userId, token or code field. `otp` must be a JSON string: sending a JSON
/// number is rejected by model binding with an ASP.NET `ProblemDetails` body.
final class ConfirmEmailRequestModel {
  const ConfirmEmailRequestModel({
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
        'otp': otp,
      };
}
