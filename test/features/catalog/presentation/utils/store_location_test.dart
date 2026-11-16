import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/catalog/presentation/utils/store_location.dart';

void main() {
  group('StoreLocation.googleMapsUri', () {
    test('uses a coordinate Google Maps search for valid coordinates', () {
      final uri = StoreLocation.googleMapsUri(
        latitude: 26.56,
        longitude: 31.69,
        address: 'Sohag',
      );

      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters, <String, String>{
        'api': '1',
        'query': '26.56,31.69',
      });
    });

    test('rejects 0,0 and falls back to a meaningful API address', () {
      final uri = StoreLocation.googleMapsUri(
        latitude: 0,
        longitude: 0,
        address: 'شارع الجمهورية، سوهاج & الدور 2',
      );

      expect(uri, isNotNull);
      expect(uri!.queryParameters['query'], 'شارع الجمهورية، سوهاج & الدور 2');
      expect(uri.toString(), contains('%D8'));
      expect(uri.toString(), contains('%26'));
    });

    test('uses the address when coordinates are out of range or incomplete',
        () {
      final outOfRange = StoreLocation.googleMapsUri(
        latitude: 91,
        longitude: 31.69,
        address: 'Sohag Governorate',
      );
      final incomplete = StoreLocation.googleMapsUri(
        latitude: 26.56,
        longitude: null,
        address: 'Sohag Governorate',
      );

      expect(outOfRange!.queryParameters['query'], 'Sohag Governorate');
      expect(incomplete!.queryParameters['query'], 'Sohag Governorate');
    });

    test('returns null when neither usable coordinates nor address exist', () {
      expect(
        StoreLocation.googleMapsUri(
          latitude: 0,
          longitude: 0,
          address: '  ',
        ),
        isNull,
      );
      expect(
        StoreLocation.googleMapsUri(
          latitude: null,
          longitude: null,
          address: 'N/A',
        ),
        isNull,
      );
    });
  });
}
