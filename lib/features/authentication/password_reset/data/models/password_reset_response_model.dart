/// The outcome of a successful `ForgotPassword` or `ResetPassword` call.
///
/// The success payload is deliberately **tolerant**. `ForgotPassword` is
/// verified to return `{"data": ""}` — an empty string, the same convention as
/// `ResendOtp` — while `ResetPassword`'s success body is **not documented** and
/// has never been observed. So `data` may be an empty string, `null`, a string
/// or an object; all are accepted and reduced to the one thing the UI needs,
/// the backend's human-readable `message`.
///
/// **No token is parsed and none is persisted.** Resetting a password is not a
/// sign-in, and nothing in the contract suggests credentials are returned, so
/// the app never auto-logs-in. If the backend later returns a token, this model
/// is the single place to extend.
final class PasswordResetResponseModel {
  const PasswordResetResponseModel({
    required this.message,
    this.payload,
  });

  /// The envelope's `message`, which is the user-facing Arabic text.
  final String message;

  /// The raw `data` payload, retained only so a future contract change (such as
  /// a token) can be detected in tests without rewriting the parser.
  final Object? payload;

  factory PasswordResetResponseModel.fromEnvelope({
    required Object? data,
    String? message,
  }) {
    final resolvedMessage = _resolveMessage(data, message);

    if (resolvedMessage == null) {
      throw const FormatException(
        'Password reset response carries no usable message',
      );
    }

    return PasswordResetResponseModel(
      message: resolvedMessage,
      payload: data,
    );
  }

  /// Prefers the envelope `message`; falls back to `data` when it is a
  /// non-empty string, which is the convention Register uses.
  static String? _resolveMessage(Object? data, String? message) {
    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    // An object payload with no envelope message is unexpected today; reject it
    // rather than silently producing an empty confirmation.
    return null;
  }

  /// True only if a future contract change starts returning a session token.
  /// Kept explicit so no caller can accidentally treat this as a sign-in.
  bool get carriesToken {
    final data = payload;
    if (data is Map<Object?, Object?>) {
      final token = data['token'];
      return token is String && token.trim().isNotEmpty;
    }
    return false;
  }
}
