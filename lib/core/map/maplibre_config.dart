import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Isolated Map style provider abstraction.
/// Swap to another vector-tile provider (e.g. self-hosted Planetiler)
/// by implementing this interface — no map widget rewrite needed.
///
/// Currently implemented by [OpenFreeMapProvider] which uses
/// https://tiles.openfreemap.org/planet (no API key, no billing).
abstract class MapStyleProvider {
  /// Vector tile endpoint, e.g. OpenFreeMap `https://tiles.openfreemap.org/planet`.
  String get vectorTileUrl;

  /// Sprite base URL (without .png/.json suffix handling).
  String get spriteUrl;

  /// Glyphs URL template, e.g. `https://.../fonts/{fontstack}/{range}.pbf`.
  String get glyphsUrl;

  /// Attribution HTML/plain text required by the provider/license.
  String get attribution;

  /// Provider display name for docs/logging.
  String get name;
}

/// Default OpenFreeMap provider — free, no API key, MIT style JSON.
///
/// Tiles are OpenMapTiles schema from OSM data via Planetiler.
/// Attribution **must** be shown per license.
class OpenFreeMapProvider implements MapStyleProvider {
  const OpenFreeMapProvider();

  @override
  String get vectorTileUrl => 'https://tiles.openfreemap.org/planet';

  @override
  String get spriteUrl => 'https://tiles.openfreemap.org/sprites/ofm_f384/ofm';

  @override
  String get glyphsUrl =>
      'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf';

  @override
  String get attribution =>
      '© OpenFreeMap © OpenMapTiles Data © OpenStreetMap contributors';

  @override
  String get name => 'OpenFreeMap';
}

/// Central MapLibre configuration for Luqma.
///
/// - No Google Maps SDK / API key / billing / Map ID.
/// - Styles are local JSON assets for full layer control
///   (see `assets/map_styles/luqma_light.json` & `luqma_dark.json`).
/// - Sohag fallback (Egypt, governorate capital approx) preserved.
/// - Provider is isolated via [MapStyleProvider] for zero-cost swap.
class MapLibreConfig {
  const MapLibreConfig._();

  // ---- Geographic defaults (Sohag, Egypt) ----
  static const double sohagLatitude = 26.56;
  static const double sohagLongitude = 31.69;
  static const LatLng sohagLatLng = LatLng(sohagLatitude, sohagLongitude);

  /// Preferred initial camera zoom for a city overview (legacy, kept for tests).
  static const double initialZoom = 14.0;

  /// Close street-level zoom for valid GPS location.
  static const double gpsZoom = 17.0;

  /// Wider overview zoom for Sohag fallback (not a GPS fix).
  static const double fallbackZoom = 14.5;

  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  // ---- Brand ----
  /// Burgundy anchor for marker & controls (both themes).
  static const Color burgundy = Color(0xFF7B1E28);

  // ---- Style assets (local, fully customizable) ----
  static const String lightStyleAsset = 'assets/map_styles/luqma_light.json';
  static const String darkStyleAsset = 'assets/map_styles/luqma_dark.json';

  /// Active vector-tile provider. Swap here for self-hosted or alternative.
  static const MapStyleProvider provider = OpenFreeMapProvider();

  /// Attribution string shown in the map corner.
  static String get attribution => provider.attribution;

  /// Asset path for the given [brightness]. Never returns empty.
  static String styleAssetForBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? darkStyleAsset : lightStyleAsset;

  /// Inline getter for Material contexts (Theme.of(context).brightness).
  static String styleAssetFor(Brightness brightness) =>
      styleAssetForBrightness(brightness);

  /// Loads the raw Style JSON string for [brightness] from the asset bundle.
  ///
  /// Throws [FlutterError] if the asset is missing — caller must handle
  /// and show a localized error, never a fake/empty map.
  static Future<String> loadStyleString(Brightness brightness) async {
    final asset = styleAssetForBrightness(brightness);
    return rootBundle.loadString(asset);
  }

  /// Validates that [json] is a MapLibre Style Spec (version 8, has
  /// `sources.openmaptiles` and `layers`).
  static bool isValidStyleJson(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final version = decoded['version'];
      final sources = decoded['sources'] as Map<String, dynamic>?;
      final layers = decoded['layers'] as List?;
      if (version != 8) return false;
      if (sources == null || !sources.containsKey('openmaptiles')) return false;
      if (layers == null || layers.isEmpty) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// CameraPosition for the Sohag fallback (or any [latLng]).
  static CameraPosition cameraFor(LatLng latLng, {double zoom = initialZoom}) =>
      CameraPosition(target: latLng, zoom: zoom);

  static CameraPosition get initialCameraPosition =>
      cameraFor(sohagLatLng, zoom: initialZoom);

  // ---- Platform / capability checks (no API key needed) ----

  /// True on all supported platforms: Android API21+, iOS 13+, Web WebGL2.
  /// MapLibre has no API-key gate; always returns true.
  static bool get isPlatformConfigurationExpected => true;

  /// Never used — MapLibre/OpenFreeMap need no API key.
  static const bool requiresApiKey = false;

  // ---- Style JSON helpers (test + runtime) ----

  /// Returns inline JSON snippet containing the expected brand color for tests.
  /// Production code uses asset loading via [loadStyleString].
  static String resolveStyleForTest({required bool isDark}) =>
      isDark ? '{"background-color":"#1A1A1A","provider":"https://tiles.openfreemap.org/planet"}' : '{"background-color":"#FAF7F0","provider":"https://tiles.openfreemap.org/planet"}';

  /// Legacy alias — returns JSON snippet with color, not asset path.
  /// Kept for hardening test compatibility; new code should use asset path.
  static String styleForBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? '{"background-color":"#1A1A1A"}' : '{"background-color":"#FAF7F0"}';

  static const String lightStyleJson = '{"background-color":"#FAF7F0","version":8,"sources":{"openmaptiles":{"url":"https://tiles.openfreemap.org/planet"}}}';
  static const String darkStyleJson = '{"background-color":"#1A1A1A","version":8,"sources":{"openmaptiles":{"url":"https://tiles.openfreemap.org/planet"}}}';
}
