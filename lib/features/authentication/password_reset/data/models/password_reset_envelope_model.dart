import 'password_reset_response_model.dart';

/// The uniform Luqma envelope: `{message, data, isSucceeded, timestamp}`.
///
/// Shared by `ForgotPassword` and `ResetPassword`. Tolerates every `data`
/// shape the backend is known to emit across its endpoints: an empty string,
/// `null`, a plain string, or an object.
final class PasswordResetEnvelopeModel {
  const PasswordResetEnvelopeModel({
    required this.isSucceeded,
    this.message,
    this.data,
    this.rawData,
  });

  final bool isSucceeded;
  final String? message;

  /// Present only when `isSucceeded` is true and the payload was usable.
  final PasswordResetResponseModel? data;

  /// The untouched `data` value, for diagnostics and contract-drift tests.
  final Object? rawData;

  factory PasswordResetEnvelopeModel.fromJson(
    Object? json, {
    String description = 'Password reset response envelope',
  }) {
    final envelope = _asStringKeyedMap(json, description);
    final isSucceeded = envelope['isSucceeded'];

    if (isSucceeded is! bool) {
      throw FormatException('Invalid $description');
    }

    final message = _nonEmptyString(envelope['message']);
    final rawData = envelope['data'];

    if (!isSucceeded) {
      return PasswordResetEnvelopeModel(
        isSucceeded: false,
        message: message,
        rawData: rawData,
      );
    }

    return PasswordResetEnvelopeModel(
      isSucceeded: true,
      message: message,
      rawData: rawData,
      data: PasswordResetResponseModel.fromEnvelope(
        data: rawData,
        message: message,
      ),
    );
  }
}

Map<String, dynamic> _asStringKeyedMap(Object? value, String description) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map<Object?, Object?>) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('Invalid $description');
      }
      result[key] = entry.value;
    }
    return result;
  }

  throw FormatException('Invalid $description');
}

String? _nonEmptyString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
