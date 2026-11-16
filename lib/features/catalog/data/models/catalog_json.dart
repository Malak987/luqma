import '../../domain/queries/catalog_identifiers.dart';

Map<Object?, Object?> catalogObject(Object? value) {
  if (value is! Map<Object?, Object?> ||
      value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected a catalog JSON object');
  }
  return value;
}

String catalogString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid catalog field: $key');
  }
  return value.trim();
}

String catalogId(Map<Object?, Object?> json, String key) {
  final value = catalogString(json, key);
  if (!isCatalogId(value))
    throw FormatException('Invalid catalog identifier: $key');
  return value;
}

String? catalogOptionalString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String)
    throw FormatException('Invalid optional catalog field: $key');
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Optional nested display data is safely ignored when an older deployment
/// sends an unexpected value. It is never used for identifiers or API queries.
String? catalogLenientOptionalString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int catalogInt(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! int)
    throw FormatException('Missing or invalid catalog integer: $key');
  return value;
}

bool catalogBool(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Missing or invalid catalog boolean: $key');
  }
  return value;
}

/// Optional server flags are nullable: absence means "unknown", never false.
bool? catalogOptionalBool(Map<Object?, Object?> json, String key) {
  final value = json[key];
  return value is bool ? value : null;
}

/// Lenient optional number: absent, null or non-numeric all read as null, so a
/// field the backend does not send yet never breaks parsing.
num? catalogOptionalNum(Map<Object?, Object?> json, String key) {
  final value = json[key];
  return value is num && value.isFinite ? value : null;
}

/// Returns only integral optional values; fractional values are not silently
/// truncated into counts or minutes.
int? catalogOptionalInt(Map<Object?, Object?> json, String key) {
  final value = catalogOptionalNum(json, key);
  if (value == null || value != value.roundToDouble()) return null;
  return value.toInt();
}
