import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/map/maplibre_config.dart';

void main() {
  group('MapLibreConfig', () {
    test('light and dark style JSON are valid and distinct', () {
      expect(MapLibreConfig.lightStyleJson, contains('#FAF7F0'));
      expect(MapLibreConfig.darkStyleJson, contains('#1A1A1A'));
      expect(MapLibreConfig.lightStyleJson, isNot(equals(MapLibreConfig.darkStyleJson)));
    });

    test('light style uses Luqma Light Ivory palette', () {
      expect(MapLibreConfig.lightStyleJson, contains('#FAF7F0'));
      expect(MapLibreConfig.lightStyleJson, isNot(contains('#1A1A1A')));
      // Must not be pure white or black for parks/water — check via asset file content is separate
    });

    test('dark style uses Minimal Charcoal palette, never pure black', () {
      expect(MapLibreConfig.darkStyleJson, contains('#1A1A1A'));
      // Ensure charcoal is used, not pure black #000000
      expect(MapLibreConfig.darkStyleJson, isNot(contains('#000000')));
      expect(MapLibreConfig.lightStyleJson, isNot(contains('#000000')));
    });

    test('styleForBrightness returns distinct light/dark with correct colors', () {
      final light = MapLibreConfig.styleForBrightness(Brightness.light);
      final dark = MapLibreConfig.styleForBrightness(Brightness.dark);
      expect(light, contains('#FAF7F0'));
      expect(dark, contains('#1A1A1A'));
      expect(light, isNot(dark));
    });

    test('resolveStyleForTest returns correct light/dark', () {
      expect(MapLibreConfig.resolveStyleForTest(isDark: false), contains('#FAF7F0'));
      expect(MapLibreConfig.resolveStyleForTest(isDark: true), contains('#1A1A1A'));
    });

    test('Sohag fallback constants preserved', () {
      expect(MapLibreConfig.sohagLatitude, 26.56);
      expect(MapLibreConfig.sohagLongitude, 31.69);
      expect(MapLibreConfig.sohagLatLng.latitude, 26.56);
      expect(MapLibreConfig.sohagLatLng.longitude, 31.69);
      expect(MapLibreConfig.initialZoom, 14.0);
    });

    test('zoom constraints are valid', () {
      expect(MapLibreConfig.minZoom, lessThan(MapLibreConfig.initialZoom));
      expect(MapLibreConfig.maxZoom, greaterThan(MapLibreConfig.initialZoom));
      expect(MapLibreConfig.minZoom, 3.0);
      expect(MapLibreConfig.maxZoom, 18.0);
    });

    test('no API key leakage in style JSON', () {
      expect(MapLibreConfig.lightStyleJson.toLowerCase(), isNot(contains('apikey')));
      expect(MapLibreConfig.darkStyleJson.toLowerCase(), isNot(contains('apikey')));
      expect(MapLibreConfig.lightStyleJson.toLowerCase(), isNot(contains('google')));
      expect(MapLibreConfig.darkStyleJson.toLowerCase(), isNot(contains('google')));
    });

    test('no Map ID or Google leakage', () {
      expect(MapLibreConfig.lightStyleJson.toLowerCase(), isNot(contains('mapid')));
      expect(MapLibreConfig.darkStyleJson.toLowerCase(), isNot(contains('mapid')));
      expect(MapLibreConfig.lightStyleJson.toLowerCase(), isNot(contains('tile.openstreetmap.org')));
      expect(MapLibreConfig.darkStyleJson.toLowerCase(), isNot(contains('tile.openstreetmap.org')));
    });

    test('uses OpenFreeMap provider with correct endpoint', () {
      expect(MapLibreConfig.provider.vectorTileUrl, 'https://tiles.openfreemap.org/planet');
      expect(MapLibreConfig.provider.name, 'OpenFreeMap');
      expect(MapLibreConfig.attribution, contains('OpenFreeMap'));
      expect(MapLibreConfig.attribution, contains('OpenStreetMap'));
      expect(MapLibreConfig.lightStyleJson, contains('https://tiles.openfreemap.org/planet'));
    });

    test('isPlatformConfigurationExpected true without API key', () {
      expect(MapLibreConfig.isPlatformConfigurationExpected, isTrue);
      expect(MapLibreConfig.requiresApiKey, isFalse);
    });

    test('styleAssetForBrightness returns distinct asset paths', () {
      final lightAsset = MapLibreConfig.styleAssetForBrightness(Brightness.light);
      final darkAsset = MapLibreConfig.styleAssetForBrightness(Brightness.dark);
      expect(lightAsset, contains('luqma_light.json'));
      expect(darkAsset, contains('luqma_dark.json'));
      expect(lightAsset, isNot(darkAsset));
    });

    test('isValidStyleJson validates spec', () {
      expect(MapLibreConfig.isValidStyleJson(MapLibreConfig.lightStyleJson), isTrue);
      expect(MapLibreConfig.isValidStyleJson(MapLibreConfig.darkStyleJson), isTrue);
      expect(MapLibreConfig.isValidStyleJson('not json'), isFalse);
      expect(MapLibreConfig.isValidStyleJson('{"version":8,"sources":{},"layers":[]}'), isFalse);
    });
  });
}
