import 'register_response_model.dart';

/// The uniform Luqma envelope: `{message, data, isSucceeded, timestamp}`.
///
/// Mirrors `LoginResponseEnvelopeModel`, with one deliberate difference: the
/// `message` is retained. Register has no error code in the body, so the
/// backend's Arabic `message` is the only description of what went wrong
/// ("هذا البريد مستخدم بالفعل", weak-password details, ...) and it is shown
/// directly to the user.
final class RegisterResponseEnvelopeModel {
  const RegisterResponseEnvelopeModel({
    required this.isSucceeded,
    this.message,
    this.data,
  });

  final bool isSucceeded;
  final String? message;
  final RegisterResponseModel? data;

  factory RegisterResponseEnvelopeModel.fromJson(Object? json) {
    final envelope = _asStringKeyedMap(json, 'Register response envelope');
    final isSucceeded = envelope['isSucceeded'];

    if (isSucceeded is! bool) {
      throw const FormatException('Invalid register response envelope');
    }

    final message = _nonEmptyString(envelope['message']);

    if (!isSucceeded) {
      return RegisterResponseEnvelopeModel(
        isSucceeded: false,
        message: message,
      );
    }

    return RegisterResponseEnvelopeModel(
      isSucceeded: true,
      message: message,
      data: RegisterResponseModel.fromJson(envelope['data']),
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
