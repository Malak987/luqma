/// The outcome of a successful `ConfirmEmail` or `ResendOtp` call.
///
/// The success payload is deliberately **tolerant**, because the two endpoints
/// are known to disagree and `ConfirmEmail`'s success body is not documented:
///
/// * `ResendOtp` returns `{"data": ""}` — an **empty string** (verified live).
/// * `Register` returns `{"data": "<same text as message>"}`.
/// * `Login` returns `{"data": {...}}` — an object holding a session.
///
/// So `data` may be an empty string, a string, an object, or absent. All are
/// accepted and reduced to the single thing the UI needs: the backend's
/// human-readable `message`.
///
/// **No token is parsed and none is persisted.** Nothing observed in the
/// contract indicates that confirming an email issues credentials, and
/// inventing auto-login would be unsafe. If the backend later returns a token,
/// this model is the single place to extend.
final class EmailVerificationResponseModel {
  const EmailVerificationResponseModel({
    required this.message,
    this.payload,
  });

  /// The envelope's `message`, which is the user-facing Arabic text.
  final String message;

  /// The raw `data` payload, retained only so a future contract change (such as
  /// a token) can be detected in tests without rewriting the parser.
  final Object? payload;

  factory EmailVerificationResponseModel.fromEnvelope({
    required Object? data,
    String? message,
  }) {
    final resolvedMessage = _resolveMessage(data, message);

    if (resolvedMessage == null) {
      throw const FormatException(
        'Email verification response carries no usable message',
      );
    }

    return EmailVerificationResponseModel(
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
  /// Kept explicit so no caller can accidentally treat the response as a
  /// successful sign-in.
  bool get carriesToken {
    final data = payload;
    if (data is Map<Object?, Object?>) {
      final token = data['token'];
      return token is String && token.trim().isNotEmpty;
    }
    return false;
  }
}
