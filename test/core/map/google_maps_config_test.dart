import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/map/google_maps_config.dart';

void main() {
  group('GoogleMapsConfig — style selection', () {
    test('lightStyleJson is warm ivory, not pure white, contains expected features', () {
      final json = GoogleMapsConfig.lightStyleJson;
      expect(json, contains('#FAF7F0')); // ivory background
      expect(json, isNot(contains('#000000'))); // never pure black
      expect(json, contains('road.highway'));
      expect(json, contains('water'));
      expect(json, contains('poi.park'));
      expect(json, contains('visibility'));
      // Must be valid JSON array string
      expect(json.trim().startsWith('['), isTrue);
      expect(json.trim().endsWith(']'), isTrue);
    });

    test('darkStyleJson is charcoal, not pure black, muted roads', () {
      final json = GoogleMapsConfig.darkStyleJson;
      expect(json, contains('#1A1A1A')); // charcoal background
      expect(json, isNot(contains('"#000000"'))); // avoid pure black geometry
      expect(json, contains('#3A3A3A')); // highway muted
      expect(json, contains('#1E2A32')); // water subtle
      expect(json, contains('road.arterial'));
      expect(json.trim().startsWith('['), isTrue);
    });

    test('light and dark styles are distinct', () {
      expect(GoogleMapsConfig.lightStyleJson, isNot(GoogleMapsConfig.darkStyleJson));
      expect(GoogleMapsConfig.lightStyleJson.contains('#FAF7F0'), isTrue);
      expect(GoogleMapsConfig.darkStyleJson.contains('#1A1A1A'), isTrue);
    });

    test('styleForBrightness selects correct JSON', () {
      expect(GoogleMapsConfig.styleForBrightness(Brightness.light), GoogleMapsConfig.lightStyleJson);
      expect(GoogleMapsConfig.styleForBrightness(Brightness.dark), GoogleMapsConfig.darkStyleJson);
    });

    test('resolveStyleForTest delegates correctly', () {
      expect(GoogleMapsConfig.resolveStyleForTest(isDark: false), contains('#FAF7F0'));
      expect(GoogleMapsConfig.resolveStyleForTest(isDark: true), contains('#1A1A1A'));
    });

    test('sohag constants match domain fallback', () {
      expect(GoogleMapsConfig.sohagLatitude, 26.56);
      expect(GoogleMapsConfig.sohagLongitude, 31.69);
      expect(GoogleMapsConfig.sohagLatLng.latitude, 26.56);
      expect(GoogleMapsConfig.sohagLatLng.longitude, 31.69);
      expect(GoogleMapsConfig.sohagCameraPosition.target.latitude, 26.56);
      expect(GoogleMapsConfig.sohagCameraPosition.zoom, GoogleMapsConfig.initialZoom);
    });

    test('zoom constraints preserve previous behavior', () {
      expect(GoogleMapsConfig.initialZoom, 14);
      expect(GoogleMapsConfig.minZoom, 3);
      expect(GoogleMapsConfig.maxZoom, 18);
    });

    test('styles are local constants, no network, no Map ID', () {
      // Styles must be local Dart strings, not URLs or Map IDs.
      expect(GoogleMapsConfig.lightStyleJson, isNot(contains('https://')));
      expect(GoogleMapsConfig.darkStyleJson, isNot(contains('https://')));
      expect(GoogleMapsConfig.lightStyleJson, isNot(contains('mapId')));
      expect(GoogleMapsConfig.darkStyleJson, isNot(contains('cloudMapId')));
    });

    test('no API key in config JSON', () {
      // Styles must not contain secrets.
      expect(GoogleMapsConfig.lightStyleJson.toLowerCase(), isNot(contains('apikey')));
      expect(GoogleMapsConfig.darkStyleJson.toLowerCase(), isNot(contains('apikey')));
      expect(GoogleMapsConfig.lightStyleJson, isNot(contains('GOOGLE_MAPS')));
    });

    test('isPlatformConfigurationExpected is true (documented)', () {
      expect(GoogleMapsConfig.isPlatformConfigurationExpected, isTrue);
    });
  });
}
