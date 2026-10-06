/// The `data` payload of a successful Register call.
///
/// Unlike Login, Register returns **no** token and **no** user object. The
/// backend sends a plain Arabic confirmation string that must be surfaced in
/// the UI, because the user still has to confirm their email before signing
/// in. `AuthSession` therefore cannot be reused here.
final class RegisterResponseModel {
  const RegisterResponseModel({required this.message});

  final String message;

  factory RegisterResponseModel.fromJson(Object? json) {
    if (json is String) {
      final trimmed = json.trim();
      if (trimmed.isNotEmpty) {
        return RegisterResponseModel(message: trimmed);
      }
      throw const FormatException(
        'Register response data is an empty string',
      );
    }

    throw const FormatException('Register response data must be a string');
  }
}
