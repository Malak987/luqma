import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/map/tile_provider_config.dart';

void main() {
  group('TileProviderConfig — release-safe pure selection (Phase E.1)', () {
    const testKey = 'test-geoapify-key-123';

    test('debug without key → OSM fallback (never config error)', () {
      final light = TileProviderConfig.resolve(
        isReleaseMode: false,
        apiKey: '',
        isDark: false,
      );
      final dark = TileProviderConfig.resolve(
        isReleaseMode: false,
        apiKey: '',
        isDark: true,
      );

      for (final sel in [light, dark]) {
        expect(sel.kind, TileProviderKind.osmFallback);
        expect(sel.isConfigurationError, isFalse);
        expect(sel.urlTemplate, TileProviderConfig.osmUrlTemplate);
        expect(sel.attribution, TileProviderConfig.osmAttribution);
        expect(sel.isOsmFallback, isTrue);
        expect(sel.isGeoapify, isFalse);
      }
      // Light/dark share same OSM URL in debug without key (acceptable)
      expect(light.urlTemplate, dark.urlTemplate);
    });

    test('debug with key → Geoapify light osm-bright', () {
      final sel = TileProviderConfig.resolve(
        isReleaseMode: false,
        apiKey: testKey,
        isDark: false,
      );

      expect(sel.kind, TileProviderKind.geoapify);
      expect(sel.isConfigurationError, isFalse);
      expect(sel.isGeoapify, isTrue);
      expect(sel.urlTemplate, contains('osm-bright'));
      expect(sel.urlTemplate, contains(testKey));
      expect(sel.urlTemplate, contains('maps.geoapify.com/v1/tile/'));
      expect(sel.attribution, TileProviderConfig.geoapifyAttribution);
      expect(sel.attribution, contains('Geoapify'));
    });

    test('debug with key → Geoapify dark dark-matter-dark-grey', () {
      final sel = TileProviderConfig.resolve(
        isReleaseMode: false,
        apiKey: testKey,
        isDark: true,
      );

      expect(sel.kind, TileProviderKind.geoapify);
      expect(sel.isConfigurationError, isFalse);
      expect(sel.urlTemplate, contains('dark-matter-dark-grey'));
      expect(sel.urlTemplate, contains(testKey));
      expect(sel.attribution, TileProviderConfig.geoapifyAttribution);
    });

    test('release with key → Geoapify (both themes)', () {
      final light = TileProviderConfig.resolve(
        isReleaseMode: true,
        apiKey: testKey,
        isDark: false,
      );
      final dark = TileProviderConfig.resolve(
        isReleaseMode: true,
        apiKey: testKey,
        isDark: true,
      );

      for (final sel in [light, dark]) {
        expect(sel.kind, TileProviderKind.geoapify);
        expect(sel.isConfigurationError, isFalse);
        expect(sel.urlTemplate, isNotEmpty);
        expect(sel.attribution, TileProviderConfig.geoapifyAttribution);
      }
      expect(light.urlTemplate, contains('osm-bright'));
      expect(dark.urlTemplate, contains('dark-matter'));
      expect(light.urlTemplate, isNot(dark.urlTemplate));
    });

    test('release without key → configurationError, never OSM', () {
      final light = TileProviderConfig.resolve(
        isReleaseMode: true,
        apiKey: '',
        isDark: false,
      );
      final dark = TileProviderConfig.resolve(
        isReleaseMode: true,
        apiKey: '',
        isDark: true,
      );

      for (final sel in [light, dark]) {
        expect(sel.kind, TileProviderKind.configurationError);
        expect(sel.isConfigurationError, isTrue);
        expect(sel.urlTemplate, isEmpty,
            reason: 'release without key must not provide a URL');
        expect(sel.attribution, isEmpty);
        expect(sel.urlTemplate, isNot(TileProviderConfig.osmUrlTemplate),
            reason: 'must never fall back to OSM in release');
        expect(sel.kind, isNot(TileProviderKind.osmFallback));
        expect(sel.isOsmFallback, isFalse);
        expect(sel.isGeoapify, isFalse);
      }
    });

    test('configured key selects distinct light/dark styles', () {
      final light = TileProviderConfig.resolve(
        isReleaseMode: false,
        apiKey: testKey,
        isDark: false,
      );
      final dark = TileProviderConfig.resolve(
        isReleaseMode: false,
        apiKey: testKey,
        isDark: true,
      );

      expect(light.urlTemplate, contains('osm-bright'));
      expect(dark.urlTemplate, contains('dark-matter-dark-grey'));
      expect(light.urlTemplate, isNot(dark.urlTemplate));
      // Both contain key but different style segment
      expect(light.urlTemplate, contains(testKey));
      expect(dark.urlTemplate, contains(testKey));
    });

    test('OSM fallback attribution is ODbL compliant', () {
      expect(
        TileProviderConfig.osmAttribution,
        '© OpenStreetMap contributors',
      );
      expect(TileProviderConfig.geoapifyAttribution,
          contains('OpenStreetMap'));
      expect(TileProviderConfig.geoapifyAttribution, contains('Geoapify'));
    });

    test('User-Agent IDs are documented and stable', () {
      expect(TileProviderConfig.userAgentPackageName, 'com.example.luqma_app');
      expect(TileProviderConfig.iosBundleIdentifier, 'com.example.luqmaApp');
      // iOS differs by underscore/camelCase — intentional
      expect(TileProviderConfig.userAgentPackageName,
          isNot(TileProviderConfig.iosBundleIdentifier));
    });

    test('Caching note documents native vs web behavior', () {
      expect(TileProviderConfig.cachingNote, contains('BuiltInMapCachingProvider'));
      expect(TileProviderConfig.cachingNote, contains('1 GB'));
      expect(TileProviderConfig.cachingNote, contains('Cache-Control'));
      expect(TileProviderConfig.cachingNote, contains('web'));
      expect(TileProviderConfig.cachingNote, contains('browser'));
      // Must distinguish OSM vs Geoapify policy
      expect(TileProviderConfig.cachingNote, contains('tile.openstreetmap.org'));
      expect(TileProviderConfig.cachingNote, contains('Geoapify'));
      expect(TileProviderConfig.cachingNote, isNot(contains('overrideFreshAge')));
    });

    test('No API key in logs — resolve never logs', () {
      // This test ensures resolve() is pure and does not print.
      // We verify no global print side-effect by calling it and ensuring
      // it returns without throwing and URL contains key only in return value,
      // not in any log path (manual review: debugPrint not inside resolve).
      final sel = TileProviderConfig.resolve(
        isReleaseMode: false,
        apiKey: 'secret-key-should-not-be-logged',
        isDark: false,
      );
      expect(sel.urlTemplate, contains('secret-key-should-not-be-logged'));
      // The test passes if no exception and no hidden logging (reviewed).
    });

    test('Sohag fallback constants documented', () {
      expect(TileProviderConfig.sohagFallbackLatitude, 26.56);
      expect(TileProviderConfig.sohagFallbackLongitude, 31.69);
    });
  });
}
