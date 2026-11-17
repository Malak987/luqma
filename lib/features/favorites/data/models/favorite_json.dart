Map<Object?, Object?> favoriteObject(Object? value, String description) {
  if (value is! Map<Object?, Object?> ||
      value.keys.any((key) => key is! String)) {
    throw FormatException('Expected a $description JSON object');
  }
  return value;
}

String favoriteRequiredString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid favorite field: $key');
  }
  return value.trim();
}

/// Descriptions and remote image values can be blank without being fabricated.
String favoriteText(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Missing or invalid favorite text field: $key');
  }
  return value.trim();
}

String? favoriteOptionalString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Invalid optional favorite field: $key');
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

num favoriteRequiredNumber(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('Missing or invalid favorite number: $key');
  }
  return value;
}

num? favoriteOptionalNumber(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw FormatException('Invalid optional favorite number: $key');
  }
  return value;
}

bool favoriteRequiredBool(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Missing or invalid favorite field: $key');
  }
  return value;
}

int favoriteRequiredNonNegativeInt(Map<Object?, Object?> json, String key) {
  final value = favoriteRequiredNumber(json, key);
  if (value != value.roundToDouble() || value < 0) {
    throw FormatException('Invalid nonnegative favorite integer: $key');
  }
  return value.toInt();
}
