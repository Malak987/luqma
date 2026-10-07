import 'email_verification_response_model.dart';

/// The uniform Luqma envelope: `{message, data, isSucceeded, timestamp}`.
///
/// Shared by `ConfirmEmail` and `ResendOtp`. Mirrors
/// `RegisterResponseEnvelopeModel`, but is **more permissive about `data`**:
/// `ResendOtp` returns `{"data": ""}`, so an empty payload is valid here
/// whereas `RegisterResponseModel` rejects an empty string.
final class EmailVerificationEnvelopeModel {
  const EmailVerificationEnvelopeModel({
    required this.isSucceeded,
    this.message,
    this.data,
    this.rawData,
  });

  final bool isSucceeded;
  final String? message;

  /// Present only when `isSucceeded` is true and the payload was usable.
  final EmailVerificationResponseModel? data;

  /// The untouched `data` value, for diagnostics and contract-drift tests.
  final Object? rawData;

  factory EmailVerificationEnvelopeModel.fromJson(
    Object? json, {
    String description = 'Email verification response envelope',
  }) {
    final envelope = _asStringKeyedMap(json, description);
    final isSucceeded = envelope['isSucceeded'];

    if (isSucceeded is! bool) {
      throw FormatException('Invalid $description');
    }

    final message = _nonEmptyString(envelope['message']);
    final rawData = envelope['data'];

    if (!isSucceeded) {
      return EmailVerificationEnvelopeModel(
        isSucceeded: false,
        message: message,
        rawData: rawData,
      );
    }

    return EmailVerificationEnvelopeModel(
      isSucceeded: true,
      message: message,
      rawData: rawData,
      data: EmailVerificationResponseModel.fromEnvelope(
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
