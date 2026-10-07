/// Extracts a human-readable message from a rejected verification response.
///
/// Three body shapes occur on these endpoints, all verified live:
///
/// 1. The Luqma envelope, for every domain-level rejection:
///    `{"message": "رمز التحقق غير صحيح أو منتهي الصلاحية",
///      "data": null, "isSucceeded": false, "timestamp": "..."}`
/// 2. ASP.NET Core `ProblemDetails` from a deserialisation failure, whose keys
///    are dotted/positional:
///    `{"errors": {"request": ["The request field is required."],
///                 "$.otp": ["The JSON value could not be converted..."]}}`
/// 3. The same `ProblemDetails` from a missing required field, whose keys are
///    **PascalCase** instead:
///    `{"errors": {"Otp": ["The Otp field is required."]}}`
///
/// All three are handled by one path: the `errors` map is walked by **value**,
/// never by key, so the key casing convention does not matter.
///
/// Returning `null` is a valid outcome meaning "no message could be
/// recovered"; the caller then falls back to a generic localized string.
abstract final class EmailVerificationFailureParser {
  static String? parse(Object? responseBody) {
    if (responseBody is! Map<Object?, Object?>) {
      return null;
    }

    final map = <String, dynamic>{};
    for (final entry in responseBody.entries) {
      if (entry.key is String) {
        map[entry.key as String] = entry.value;
      }
    }

    return _envelopeMessage(map) ?? _problemDetailsMessage(map);
  }

  static String? _envelopeMessage(Map<String, dynamic> map) {
    if (map['isSucceeded'] != false) {
      return null;
    }
    return _nonEmptyString(map['message']);
  }

  static String? _problemDetailsMessage(Map<String, dynamic> map) {
    if (!map.containsKey('errors')) {
      return null;
    }

    final title = _nonEmptyString(map['title']);
    final errors = map['errors'];
    final details = <String>[];

    if (errors is Map<Object?, Object?>) {
      for (final value in errors.values) {
        if (value is List) {
          details.addAll(
            value
                .whereType<String>()
                .map((entry) => entry.trim())
                .where((entry) => entry.isNotEmpty),
          );
        } else if (value is String && value.trim().isNotEmpty) {
          details.add(value.trim());
        }
      }
    }

    if (details.isNotEmpty) {
      return title == null
          ? details.join(', ')
          : <String>[title, ...details].join(' — ');
    }

    return title;
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
