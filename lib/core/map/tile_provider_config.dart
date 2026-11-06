import 'package:flutter/foundation.dart';

/// Isolated tile-provider configuration for the map picker.
///
/// Keeps URL/template, attribution and licensing notes in one place so the
/// provider can be swapped without touching presentation code.
///
/// **Phase E — Premium Minimal:** Geoapify raster tiles provide a
/// minimal light map (`osm-bright`) and minimal charcoal dark map
/// (`dark-matter-dark-grey`). The key is injected via `--dart-define` to
/// avoid committing secrets. Without a key the map falls back to the public
/// OSM tiles so development never blocks.
///
/// No tile prefetching, bulk downloading or offline caching is implemented.
/// OpenStreetMap tiles are used for fallback; they are **not** guaranteed for
/// commercial production. Review the OSM Tile Usage Policy before production
/// use: https://operations.osmfoundation.org/policies/tiles/
abstract final class TileProviderConfig {
  // ---------------------------------------------------------------------------
  // API key — injected at compile time, never committed.
  // Run with: flutter run --dart-define=GEOAPIFY_API_KEY=YOUR_KEY
  // CI: pass via --dart-define in workflow or secure env.
  // ---------------------------------------------------------------------------
  static const String _geoapifyApiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '',
  );

  /// True when a Geoapify key is available at compile time.
  static bool get hasGeoapifyKey => _geoapifyApiKey.isNotEmpty;

  /// Exposed for debugging only — do not log the value.
  static bool get isUsingPremiumTiles => hasGeoapifyKey;

  // ---------------------------------------------------------------------------
  // OSM fallback — always available, no key required.
  // ---------------------------------------------------------------------------
  /// Standard OSM raster tile template (fallback).
  static const String osmUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Visible attribution required by the OSM licence (ODbL).
  static const String osmAttribution = '© OpenStreetMap contributors';

  // ---------------------------------------------------------------------------
  // Geoapify premium — Minimal Light / Minimal Charcoal (Phase E)
  // ---------------------------------------------------------------------------
  /// Geoapify light style: clean minimal with soft neutral background,
  /// subtle roads and readable labels. Suitable for Luqma Light Theme.
  /// Preview: https://apidocs.geoapify.com/docs/maps/map-tiles/
  static const String _geoapifyLightStyle = 'osm-bright';

  /// Geoapify dark style: premium Minimal Charcoal — deep charcoal
  /// background, differentiated roads, soft gray labels, low visual noise.
  /// Chosen among dark-matter variants for best Luqma contrast.
  static const String _geoapifyDarkStyle = 'dark-matter-dark-grey';

  /// Base Geoapify raster tile URL (XYZ, 256px).
  /// Use with `TileLayer(urlTemplate: url, ...)` in `flutter_map`.
  static const String _geoapifyBaseUrl =
      'https://maps.geoapify.com/v1/tile/{style}/{z}/{x}/{y}.png';

  /// Retina variant (512px, @2x) — use when `MediaQuery.devicePixelRatio >= 2`.
  static const String _geoapifyRetinaUrl =
      'https://maps.geoapify.com/v1/tile/{style}/{z}/{x}/{y}@2x.png';

  /// Light map tile URL for the current configuration.
  /// When a Geoapify key is present, uses `osm-bright`; otherwise OSM fallback.
  static String get lightUrlTemplate =>
      hasGeoapifyKey ? _geoapifyUrlForStyle(_geoapifyLightStyle) : osmUrlTemplate;

  /// Dark map tile URL for the current configuration.
  /// When a Geoapify key is present, uses `dark-matter-dark-grey`; otherwise
  /// still uses OSM fallback (but with dark background container for contrast).
  static String get darkUrlTemplate =>
      hasGeoapifyKey ? _geoapifyUrlForStyle(_geoapifyDarkStyle) : osmUrlTemplate;

  /// Resolves the correct tile URL for the active theme brightness.
  static String urlFor({required bool isDark}) =>
      isDark ? darkUrlTemplate : lightUrlTemplate;

  /// Retina-aware URL for the active theme.
  static String retinaUrlFor({required bool isDark}) {
    if (!hasGeoapifyKey) return urlFor(isDark: isDark);
    final style = isDark ? _geoapifyDarkStyle : _geoapifyLightStyle;
    return 'https://maps.geoapify.com/v1/tile/$style/{z}/{x}/{y}@2x.png?apiKey=$_geoapifyApiKey';
  }

  static String _geoapifyUrlForStyle(String style) =>
      'https://maps.geoapify.com/v1/tile/$style/{z}/{x}/{y}.png?apiKey=$_geoapifyApiKey';

  // ---------------------------------------------------------------------------
  // Attribution — must always be visible per provider licences.
  // ---------------------------------------------------------------------------
  /// Combined attribution for premium tiles (Geoapify + OSM data).
  static const String geoapifyAttribution =
      '© OpenMapTiles © OpenStreetMap contributors | Powered by Geoapify';

  /// Legacy alias for backwards compatibility with existing tests.
  static const String attribution = osmAttribution;

  /// Active attribution string for the current configuration.
  static String get activeAttribution =>
      hasGeoapifyKey ? geoapifyAttribution : osmAttribution;

  /// Attribution that respects the app language? Keep static for now.
  static String attributionFor({required bool hasPremiumKey}) =>
      hasPremiumKey ? geoapifyAttribution : osmAttribution;

  // ---------------------------------------------------------------------------
  // Human-readable notes
  // ---------------------------------------------------------------------------
  /// Human-readable note — shown in code/docs, not claimed as guarantee.
  static const String tileProviderNote =
      'Premium: Geoapify tiles (osm-bright / dark-matter-dark-grey) when '
      'GEOAPIFY_API_KEY is set via --dart-define; fallback to OSM public tiles. '
      'For commercial production, verify Geoapify pricing at '
      'https://www.geoapify.com/pricing/ and OSM policy at '
      'https://operations.osmfoundation.org/policies/tiles/. '
      'Free tier: 3000 credits/day (~12000 tiles/day, 0.25cr/tile), no card, '
      'commercial allowed with attribution. Do not commit API keys.';

  /// Fallback constant for reuse — kept here as documentation alias.
  /// The actual fallback coordinates live in [LocationCoordinates.sohagMapStartFallback].
  static const double sohagFallbackLatitude = 26.56;
  static const double sohagFallbackLongitude = 31.69;

  /// One-line setup hint for README/docs.
  static const String setupHint =
      'flutter run --dart-define=GEOAPIFY_API_KEY=YOUR_GEOAPIFY_KEY';
}
