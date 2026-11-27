import 'package:flutter/foundation.dart';

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
  if (value is int) return value;
  // Accept integral doubles (e.g. 1.0) instead of failing the whole page.
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('Missing or invalid catalog integer: $key');
}

/// Localized name that tolerates one language being blank/null: falls back to
/// the other language instead of rejecting the whole record.
String catalogName(Map<Object?, Object?> json, String key, String otherKey) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  final other = json[otherKey];
  if (other is String && other.trim().isNotEmpty) return other.trim();
  throw FormatException('Missing or invalid catalog field: $key');
}

/// Parses list items one by one. A single malformed item is skipped (and
/// logged in debug) instead of making the whole page fail.
List<T> catalogLenientList<T>(
  List<Object?> raw,
  T Function(Object?) parse, {
  String label = 'item',
}) {
  final result = <T>[];
  for (var i = 0; i < raw.length; i++) {
    try {
      result.add(parse(raw[i]));
    } on FormatException catch (e) {
      debugPrint('[catalog] skipped malformed $label #$i: ${e.message}');
    }
  }
  return List<T>.unmodifiable(result);
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

/// Reads the store photo gallery from `images` with a stable first slot.
///
/// `images[0]` is either the usable first URL or an empty string: an unusable
/// first entry is never replaced by a later photo, because the card's cover
/// priority depends on index 0 meaning "the photo the owner listed first", not
/// "the first photo the app happened to accept". Later unusable entries are
/// dropped.
List<String> catalogStoreImages(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! List<Object?> || value.isEmpty) return const <String>[];

  final first = _usableImageUrl(value.first) ?? '';
  final rest = <String>[];
  for (final item in value.skip(1)) {
    final url = _usableImageUrl(item);
    if (url != null) rest.add(url);
  }
  return List<String>.unmodifiable(<String>[first, ...rest]);
}

/// An absolute `http`/`https` URL without whitespace, or null.
String? _usableImageUrl(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.contains(RegExp(r'\s'))) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  return trimmed;
}

/// Reads the Store API price band.
///
/// `Store/GetAll` publishes the band as a positive integer (`2`), which maps to
/// the equivalent number of currency symbols (`$$`). Payloads that still send
/// display text (`$$`, `mid`) are kept as supplied. Anything else — including
/// `0`, negatives, fractions above the documented band, or blank text — reads
/// as null so the UI hides it instead of inventing a value.
String? catalogPriceLevel(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  final band = catalogOptionalInt(json, key);
  if (band == null || band <= 0 || band > 5) return null;
  return List<String>.filled(band, r'$').join();
}
