/// Payload for `POST /api/Account/Register`.
///
/// Field names, casing and types mirror the backend `RegisterRequest` schema
/// exactly, which declares `additionalProperties: false`; sending an unknown
/// key would be rejected.
///
/// `role` is not exposed to callers: registration always creates a default
/// customer account. The backend rejects higher roles
/// ("لا يمكن التسجيل بهذه الصلاحية"), so this is a deliberate constant.
final class RegisterRequestModel {
  const RegisterRequestModel({
    required this.userName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
    required this.address,
  });

  static const int defaultRole = 0;

  final String userName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phoneNumber;
  final String address;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userName': userName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'phoneNumber': phoneNumber,
        'address': address,
        'role': defaultRole,
      };
}
