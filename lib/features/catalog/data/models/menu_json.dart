/// Menu GET-specific primitive rules, reusing the existing catalog object,
/// UUID, boolean, integer and success-envelope parsing elsewhere.
num menuNumber(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('Invalid menu numeric field: $key');
  }
  return value;
}

num? menuOptionalNumber(Map<Object?, Object?> json, String key) =>
    json[key] == null ? null : menuNumber(json, key);

/// Descriptions and image URLs may legitimately be blank strings. Missing
/// required text keys are still errors; no ID-based customer fallback exists.
String menuText(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Invalid menu text field: $key');
  return value.trim();
}

List<Object?> menuOptionalArray(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value == null) return const [];
  if (value is! List<Object?>)
    throw FormatException('Invalid menu array: $key');
  return value;
}
