import 'package:url_launcher/url_launcher.dart';

/// Constructor-injectable side effect used by the store card.
typedef StoreLocationLauncher = Future<bool> Function(Uri uri);

/// Builds a Google Maps search URL from authoritative Store API values.
///
/// Coordinates are preferred only when both are finite, in range, and not the
/// unusable 0,0 placeholder. A meaningful API address is the safe fallback.
abstract final class StoreLocation {
  static Uri? googleMapsUri({
    required double? latitude,
    required double? longitude,
    required String? address,
  }) {
    if (_hasValidCoordinates(latitude, longitude)) {
      return _searchUri(
          '${_coordinateText(latitude!)},${_coordinateText(longitude!)}');
    }

    final query = _meaningfulAddress(address);
    return query == null ? null : _searchUri(query);
  }

  static bool _hasValidCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  static String? _meaningfulAddress(String? address) {
    final value = address?.trim() ?? '';
    if (value.isEmpty ||
        value.toLowerCase() == 'null' ||
        value.toLowerCase() == 'n/a' ||
        value.toLowerCase() == 'na') {
      return null;
    }
    return RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(value)
        ? value
        : null;
  }

  static String _coordinateText(double value) {
    final text = value.toString();
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  static Uri _searchUri(String query) => Uri.https(
        'www.google.com',
        '/maps/search/',
        <String, String>{'api': '1', 'query': query},
      );
}

/// Opens the generated URL outside the app. A false result is intentionally
/// returned to the card so it can provide localized, non-crashing feedback.
Future<bool> launchStoreLocation(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
