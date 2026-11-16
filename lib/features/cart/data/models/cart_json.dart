Map<Object?, Object?> cartObject(Object? value, String description) {
  if (value is! Map<Object?, Object?> ||
      value.keys.any((key) => key is! String)) {
    throw FormatException('Expected a $description JSON object');
  }
  return value;
}

String cartRequiredString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid cart field: $key');
  }
  return value.trim();
}

String? cartOptionalString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Invalid optional cart field: $key');
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

num cartRequiredNumber(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('Missing or invalid cart number: $key');
  }
  return value;
}

num? cartOptionalNumber(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw FormatException('Invalid optional cart number: $key');
  }
  return value;
}

int cartRequiredNonNegativeInt(Map<Object?, Object?> json, String key) {
  final value = cartRequiredNumber(json, key);
  if (value != value.roundToDouble() || value < 0) {
    throw FormatException('Invalid nonnegative cart integer: $key');
  }
  return value.toInt();
}

int cartRequiredPositiveInt(Map<Object?, Object?> json, String key) {
  final result = cartRequiredNonNegativeInt(json, key);
  if (result == 0) {
    throw FormatException('Invalid positive cart integer: $key');
  }
  return result;
}

bool cartRequiredBool(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Missing or invalid cart field: $key');
  }
  return value;
}

List<Object?> cartRequiredList(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw FormatException('Missing or invalid cart array: $key');
  }
  return value;
}
