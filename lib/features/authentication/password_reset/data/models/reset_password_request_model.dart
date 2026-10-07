/// Payload for `POST /api/Account/ResetPassword`.
///
/// All three fields must be JSON strings. Sending `newPassword` as a JSON
/// number is rejected by model binding with an ASP.NET `ProblemDetails` body
/// whose error key is `"$.newPassword"`.
final class ResetPasswordRequestModel {
  const ResetPasswordRequestModel({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      };
}
