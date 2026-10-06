/// Extracts a human-readable message from a rejected Register response.
///
/// The backend answers a failed registration with **two different shapes**,
/// both observed live on `POST /api/Account/Register`, so both are accepted:
///
/// 1. The Luqma envelope, used for every domain-level rejection:
///    `{"message": "هذا البريد مستخدم بالفعل", "data": null,
///      "isSucceeded": false, "timestamp": "..."}`
/// 2. ASP.NET Core `ProblemDetails`, used when the body cannot be deserialised:
///    `{"type": "...", "title": "...", "status": 400,
///      "errors": {...}, "traceId": "..."}`
///
/// Returning `null` is a valid outcome and simply means "no message could be
/// recovered"; the caller then falls back to a generic localized string.
abstract final class RegisterFailureParser {
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

    if (errors is Map<Object?, Object?>) {
      final details = <String>[];
      for (final value in errors.values) {
        if (value is List) {
          details.addAll(
            value.whereType<String>().map((entry) => entry.trim()).where(
                  (entry) => entry.isNotEmpty,
                ),
          );
        } else if (value is String && value.trim().isNotEmpty) {
          details.add(value.trim());
        }
      }

      if (details.isNotEmpty) {
        return title == null
            ? details.join(', ')
            : <String>[title, ...details].join(' — ');
      }
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
