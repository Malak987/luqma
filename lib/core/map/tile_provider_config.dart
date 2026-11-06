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
/// OSM tiles in debug/development only.
///
/// **Phase E.1 — Production hardening:**
/// - Release without a key shows a localized configuration error, never OSM.
/// - Provider selection is a pure, testable function taking `isReleaseMode`
///   and `apiKey` as parameters; the widget uses the real `kReleaseMode`.
/// - Caching is via `flutter_map >=8.2.0` built-in provider (no custom config).
/// - User-Agent is `com.example.luqma_app` (Android applicationId).
///
/// No tile prefetching, bulk downloading or offline caching is implemented.
/// OpenStreetMap tiles are used for debug fallback only; they are **not**
/// guaranteed for commercial production. Review the OSM Tile Usage Policy
/// before production use: https://operations.osmfoundation.org/policies/tiles/
enum TileProviderKind {
  /// Geoapify premium raster (light: osm-bright, dark: dark-matter-dark-grey).
  geoapify,

  /// Public OSM fallback — debug/development only.
  osmFallback,

  /// Release build has no key — show localized config error, never OSM.
  configurationError,
}

/// Pure, testable tile-provider selection result.
@immutable
class TileProviderSelection {
  const TileProviderSelection({
    required this.kind,
    required this.urlTemplate,
    required this.attribution,
    required this.isConfigurationError,
  });

  /// Which provider was selected.
  final TileProviderKind kind;

  /// Resolved URL template to pass to `TileLayer(urlTemplate:)`.
  /// Empty when [isConfigurationError] is true.
  final String urlTemplate;

  /// Attribution string for the current selection.
  final String attribution;

  /// True only when `isReleaseMode && apiKey.isEmpty`.
  final bool isConfigurationError;

  /// Convenience: true when Geoapify is selected.
  bool get isGeoapify => kind == TileProviderKind.geoapify;

  /// Convenience: true when OSM fallback is selected.
  bool get isOsmFallback => kind == TileProviderKind.osmFallback;
}

abstract final class TileProviderConfig {
  // ---------------------------------------------------------------------------
  // API key — injected at compile time, never committed.
  // Run with: flutter run --dart-define=GEOAPIFY_API_KEY=YOUR_KEY
  // CI: pass via --dart-define in workflow or secure env.
  // Treat as config, not a secret: it is extractable from the APK. Restrict
  // via allowed IP / HTTP referrer / Origin at myprojects.geoapify.com.
  // Never log the value.
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
  // OSM fallback — debug/development only.
  // ---------------------------------------------------------------------------
  /// Standard OSM raster tile template (debug fallback only).
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

  // ---------------------------------------------------------------------------
  // Pure, testable provider selection — all 4 combinations covered.
  // ---------------------------------------------------------------------------
  /// Pure selection logic — does not read [kReleaseMode] or
  /// `String.fromEnvironment` directly, so it can be unit-tested deterministically.
  ///
  /// Rules:
  /// - `apiKey.isNotEmpty` → Geoapify (both debug and release).
  /// - `apiKey.isEmpty && !isReleaseMode` → OSM fallback (debug/development).
  /// - `apiKey.isEmpty && isReleaseMode` → configurationError (never OSM).
  static TileProviderSelection resolve({
    required bool isReleaseMode,
    required String apiKey,
    required bool isDark,
  }) {
    final hasKey = apiKey.isNotEmpty;
    if (hasKey) {
      final style = isDark ? _geoapifyDarkStyle : _geoapifyLightStyle;
      final url = 'https://maps.geoapify.com/v1/tile/$style/{z}/{x}/{y}.png?apiKey=$apiKey';
      return TileProviderSelection(
        kind: TileProviderKind.geoapify,
        urlTemplate: url,
        attribution: geoapifyAttribution,
        isConfigurationError: false,
      );
    }
    if (!isReleaseMode) {
      return const TileProviderSelection(
        kind: TileProviderKind.osmFallback,
        urlTemplate: osmUrlTemplate,
        attribution: osmAttribution,
        isConfigurationError: false,
      );
    }
    // Release without key — fail safely.
    return const TileProviderSelection(
      kind: TileProviderKind.configurationError,
      urlTemplate: '',
      attribution: '',
      isConfigurationError: true,
    );
  }

  /// Convenience that reads the real compile-time key and [kReleaseMode].
  /// Production widget must use this (not a test double).
  static TileProviderSelection resolveForCurrent({required bool isDark}) {
    return resolve(
      isReleaseMode: kReleaseMode,
      apiKey: _geoapifyApiKey,
      isDark: isDark,
    );
  }

  // ---------------------------------------------------------------------------
  // Backwards-compatible getters (used by existing tests / docs).
  // They delegate to [resolveForCurrent] so behavior stays consistent.
  // ---------------------------------------------------------------------------

  /// Light map tile URL for the current configuration.
  /// Debug without key → OSM; with key → Geoapify osm-bright; release
  /// without key → '' (caller must check [isConfigurationError]).
  static String get lightUrlTemplate =>
      resolveForCurrent(isDark: false).urlTemplate;

  /// Dark map tile URL for the current configuration.
  /// Debug without key → OSM; with key → dark-matter-dark-grey; release
  /// without key → ''.
  static String get darkUrlTemplate =>
      resolveForCurrent(isDark: true).urlTemplate;

  /// Resolves the correct tile URL for the active theme brightness.
  /// Returns '' when in configuration-error state (caller should show error UI).
  static String urlFor({required bool isDark}) =>
      resolveForCurrent(isDark: isDark).urlTemplate;

  /// Retina-aware URL for the active theme.
  /// Returns '' in configuration-error state; OSM fallback ignores retina.
  static String retinaUrlFor({required bool isDark}) {
    if (isTileConfigError(isDark: isDark)) return '';
    final selection = resolveForCurrent(isDark: isDark);
    if (selection.isOsmFallback) return selection.urlTemplate;
    final style = isDark ? _geoapifyDarkStyle : _geoapifyLightStyle;
    return 'https://maps.geoapify.com/v1/tile/$style/{z}/{x}/{y}@2x.png?apiKey=$_geoapifyApiKey';
  }

  /// True when the current compile-time config is in release-without-key error.
  static bool isTileConfigError({required bool isDark}) =>
      resolveForCurrent(isDark: isDark).isConfigurationError;

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

  /// Active attribution string for the current compile-time configuration.
  /// Returns '' in configuration-error state (no map to attribute).
  static String get activeAttribution =>
      resolveForCurrent(isDark: false).attribution.isNotEmpty
          ? resolveForCurrent(isDark: false).attribution
          : _activeAttributionFallback();

  // Helper to pick attribution that matches the actual theme at call time
  // would require isDark; this getter is kept for legacy callers that don't
  // pass isDark. It returns OSM or Geoapify depending on key presence; in
  // release-without-key it intentionally returns '' to signal error, but
  // legacy fallback preserves OSM for safety where widget hasn't migrated.
  static String _activeAttributionFallback() {
    // If release without key, legacy callers would previously get OSM;
    // now we return '' so new code can detect error, but avoid breaking
    // old attribution test that runs in debug (kReleaseMode == false).
    if (kReleaseMode && !hasGeoapifyKey) return '';
    return hasGeoapifyKey ? geoapifyAttribution : osmAttribution;
  }

  /// Attribution that respects explicit key presence (for tests).
  static String attributionFor({required bool hasPremiumKey}) =>
      hasPremiumKey ? geoapifyAttribution : osmAttribution;

  // ---------------------------------------------------------------------------
  // Caching — flutter_map >=8.2.0 built-in caching.
  // ---------------------------------------------------------------------------
  /// Caching documentation for maintainers.
  ///
  /// **Native (Android/iOS/macOS/Linux/Windows):**
  /// `flutter_map` 8.2.0+ enables `BuiltInMapCachingProvider` automatically
  /// when using `NetworkTileProvider` (the default `TileLayer.tileProvider`).
  /// We do NOT set `tileProvider` explicitly — the default is used and must
  /// not be overridden with redundant `NetworkTileProvider(cachingProvider: …)`
  /// config. Behavior:
  /// - Stores tiles in the platform cache directory, OS may clear at any time.
  /// - Respects HTTP cache headers (`Cache-Control`, `Expires`, `ETag`).
  /// - Soft limit 1 GB, applied when the provider initializes (first tiles
  ///   each app session). No `overrideFreshAge` is set — we respect provider
  ///   directives (do NOT force 7 days over valid headers).
  /// - Only tiles for the current viewport are requested (no prefetch, no
  ///   bulk/offline-region download).
  ///
  /// **Web:** No `BuiltInMapCachingProvider` (dart:io unavailable). The
  /// browser's HTTP cache handles caching automatically via the same headers.
  ///
  /// **Provider-specific policy:**
  /// - `tile.openstreetmap.org` tiles: honor `Cache-Control`/`Expires`/`ETag`
  ///   or ≥7 days if unreadable; never send `Cache-Control: no-cache`; at
  ///   most 2 connections/host; bulk scrape forbidden. Our code respects
  ///   this by not disabling caching and not prefetching.
  /// - `maps.geoapify.com` tiles: Geoapify's own cache headers govern
  ///   freshness; its terms allow caching/storing tiles. We respect those
  ///   headers identically (no override). Do not claim OSM 7-day fallback
  ///   applies to Geoapify.
  static const String cachingNote =
      'Caching: flutter_map >=8.2.0 NetworkTileProvider + BuiltInMapCachingProvider '
      '(native) / browser HTTP cache (web), 1 GB soft limit, respects '
      'Cache-Control/Expires/ETag, no overrideFreshAge, no prefetch/bulk. '
      'OSM 7-day rule applies only to tile.openstreetmap.org; Geoapify respects '
      'its own headers.';

  // ---------------------------------------------------------------------------
  // User-Agent / Application IDs.
  // ---------------------------------------------------------------------------
  /// **User-Agent / Application IDs:**
  /// - Android: `com.example.luqma_app` — `android/app/build.gradle.kts`
  ///   `namespace` and `applicationId` (stable, verified).
  /// - iOS: `com.example.luqmaApp` — `ios/Runner.xcodeproj`
  ///   `PRODUCT_BUNDLE_IDENTIFIER` (differs by underscore vs camelCase).
  /// - `TileLayer(userAgentPackageName: 'com.example.luqma_app')` uses the
  ///   Android ID for both platforms for tile attribution compliance. On web
  ///   the browser's User-Agent cannot be overridden (flutter_map/doc).
  static const String userAgentPackageName = 'com.example.luqma_app';

  /// iOS bundle identifier (documented difference, not used for tiles).
  static const String iosBundleIdentifier = 'com.example.luqmaApp';

  // ---------------------------------------------------------------------------
  // Human-readable notes
  // ---------------------------------------------------------------------------
  /// Human-readable note — shown in code/docs, not claimed as guarantee.
  static const String tileProviderNote =
      'Premium: Geoapify tiles (osm-bright / dark-matter-dark-grey) when '
      'GEOAPIFY_API_KEY is set via --dart-define; debug fallback to OSM public tiles. '
      'Release without key shows configuration error (never OSM). '
      'For commercial production, verify Geoapify pricing at '
      'https://www.geoapify.com/pricing/ and OSM policy at '
      'https://operations.osmfoundation.org/policies/tiles/. '
      'Free tier: 3000 credits/day (~12000 tiles/day, 0.25cr/tile), no card, '
      'commercial allowed with attribution. Do not commit API keys. '
      ' Restrict key via allowed IP / HTTP referrer / Origin at myprojects.geoapify.com.';

  /// Fallback constant for reuse — kept here as documentation alias.
  /// The actual fallback coordinates live in [LocationCoordinates.sohagMapStartFallback].
  static const double sohagFallbackLatitude = 26.56;
  static const double sohagFallbackLongitude = 31.69;

  /// One-line setup hint for README/docs.
  static const String setupHint =
      'flutter run --dart-define=GEOAPIFY_API_KEY=YOUR_GEOAPIFY_KEY';

  /// Build hints per mode.
  static const String debugSetupHint =
      'flutter run --dart-define=GEOAPIFY_API_KEY=YOUR_KEY  (debug may omit key and use OSM)';
  static const String releaseSetupHint =
      'flutter build apk --release --dart-define=GEOAPIFY_API_KEY=YOUR_KEY  (release without key shows config error)';
}
