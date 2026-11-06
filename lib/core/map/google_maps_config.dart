import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Isolated Google Maps configuration layer.
///
/// Keeps map styling, camera defaults, and platform configuration notes
/// in one place so the platform implementation can be swapped without
/// touching presentation code.
///
/// **Google Maps SDK migration:** Replaces the previous `flutter_map`/
/// Geoapify/ OSM raster-tile stack. Uses local JSON styles that work
/// without a Google Cloud Map ID and require no network request for styling.
///
/// No WebView, no raster tile URL templates, no OSM/Geoapify fallback.
abstract final class GoogleMapsConfig {
  // -------------------------------------------------------------------------
  // Camera / location constants — Sohag fallback preserved.
  // -------------------------------------------------------------------------
  /// Sohag city-centre fallback — must match [LocationCoordinates.sohagMapStartFallback].
  static const double sohagLatitude = 26.56;
  static const double sohagLongitude = 31.69;

  /// Default initial zoom (preserves previous 14).
  static const double initialZoom = 14;

  /// Zoom constraints (preserves previous min 3 / max 18).
  static const double minZoom = 3;
  static const double maxZoom = 18;

  /// Sohag fallback as Google Maps [LatLng].
  static const LatLng sohagLatLng = LatLng(sohagLatitude, sohagLongitude);

  /// Initial camera for Sohag fallback.
  static const CameraPosition sohagCameraPosition = CameraPosition(
    target: sohagLatLng,
    zoom: initialZoom,
  );

  /// Creates a [CameraPosition] from validated domain coordinates.
  static CameraPosition cameraFor({
    required double latitude,
    required double longitude,
    double zoom = initialZoom,
  }) {
    return CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom,
    );
  }

  // -------------------------------------------------------------------------
  // Platform API key handling — never log keys, never commit secrets.
  //
  // Android: <meta-data android:name="com.google.android.geo.API_KEY"
  //           android:value="${GOOGLE_MAPS_API_KEY}" /> in AndroidManifest.xml
  //           with value resolved from local.properties (untracked).
  // iOS: GMSServices.provideAPIKey("...") in AppDelegate.swift via
  //      untracked configuration (see ios/Runner/README_MAPS.md).
  // Dart --dart-define alone does NOT configure native SDKs.
  // -------------------------------------------------------------------------

  /// Whether the Google Maps SDK is expected to be configured on this platform.
  ///
  /// In production this should always be true after developer inserts keys
  /// locally. Dart cannot directly verify native manifest/AppDelegate keys,
  /// so this remains a documentation anchor. The page handles missing config
  /// by showing a localized error instead of a fake map.
  static bool get isPlatformConfigurationExpected => true;

  // -------------------------------------------------------------------------
  // Map styling — local JSON, no network, no Map ID.
  // -------------------------------------------------------------------------

  /// Light style — **Luqma Ivory**
  /// - Warm ivory background (#F6F1E7 / #FAF7F0) — matches [AppSemanticColors.light.background]
  /// - Soft neutral roads, clear hierarchy (highway #D8D0BA, arterial #EBE5D6, local #FFFFFF)
  /// - Muted labels (#5A4A44 / #7A6A5A), low icon density (POI off)
  /// - Subtle park/green (#D8E3D0), water (#B8D4E3), minimal noise
  static const String lightStyleJson = '''
[
  {"elementType":"geometry","stylers":[{"color":"#FAF7F0"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#5A4A44"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#FAF7F0"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#D8E3D0"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6B8E6B"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFFFFF"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#EBE5D6"}]},
  {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"color":"#EBE5D6"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#D8D0BA"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#C8BFA8"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#4A3C2A"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#6B5D4F"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#B8D4E3"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4A6B7A"}]}
]
''';

  /// Dark style — **Luqma Minimal Charcoal**
  /// - Deep charcoal background (#1A1A1A) — never pure black
  /// - Muted dark-gray roads (highway #3A3A3A, arterial #2E2E2E, local #2A2A2A)
  /// - Readable labels (#9E9E9E / #B8B8B8), controlled contrast
  /// - Subtle water (#1E2A32), park (#1F2B1F), no pure-black noise
  static const String darkStyleJson = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1A1A1A"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9E9E9E"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1A1A1A"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2A2A2A"},{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1F2B1F"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#5A7A5A"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2A2A2A"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#2E2E2E"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3A3A3A"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#404040"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#252525"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#8A8A8A"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"transit.station","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#1E2A32"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#6B8291"}]}
]
''';

  /// Returns the correct style JSON for the given brightness.
  static String styleForBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? darkStyleJson : lightStyleJson;
  }

  /// Applies the theme-appropriate style to an existing [GoogleMapController].
  ///
  /// Preserves camera position — only style changes. Safe to call on every
  /// theme change (light → dark, dark → light) without recreating the map.
  /// Catches [MissingPluginException] for tests where platform channel is unavailable.
  static Future<void> applyStyle(
    GoogleMapController? controller,
    Brightness brightness,
  ) async {
    if (controller == null) return;
    final json = styleForBrightness(brightness);
    try {
      // setMapStyle is the official way to apply local JSON without a Map ID.
      // ignore: invalid_use_of_visible_for_testing_member
      await controller.setMapStyle(json);
    } on MissingPluginException catch (e) {
      debugPrint('[GoogleMapsConfig] setMapStyle unavailable in test: $e');
    } catch (e) {
      // Never log API keys; styling JSON contains no secrets.
      debugPrint('[GoogleMapsConfig] failed to apply map style: $e');
    }
  }

  /// Resolves the style for the current [Brightness] without needing a controller.
  /// Useful for tests that verify correct style selection.
  static String resolveStyleForTest({required bool isDark}) {
    return isDark ? darkStyleJson : lightStyleJson;
  }
}
