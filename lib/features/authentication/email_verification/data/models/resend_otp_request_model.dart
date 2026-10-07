/// Payload for `POST /api/Account/ResendOtp`.
final class ResendOtpRequestModel {
  const ResendOtpRequestModel({required this.email});

  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
      };
}
