import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/location/domain/entities/current_location_outcome.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';

void main() {
  group('LocationCoordinates', () {
    test('validates latitude and longitude ranges', () {
      expect(
        LocationCoordinates.fromDevice(latitude: 90, longitude: 180)
            .isDeviceDetected,
        isTrue,
      );
      expect(
        LocationCoordinates.fromMapSelection(latitude: -90, longitude: -180)
            .isDeviceDetected,
        isFalse,
      );

      expect(
        () => LocationCoordinates.fromMapSelection(
          latitude: 90.001,
          longitude: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => LocationCoordinates.fromMapSelection(
          latitude: 0,
          longitude: -180.001,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-finite coordinate values', () {
      expect(
        () => LocationCoordinates.fromDevice(
          latitude: double.nan,
          longitude: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => LocationCoordinates.fromMapSelection(
          latitude: 0,
          longitude: double.infinity,
        ),
        throwsArgumentError,
      );
    });

    test('Sohag fallback is an approximate map start, not a GPS fix', () {
      const fallback = LocationCoordinates.sohagMapStartFallback;

      expect(fallback.latitude, 26.5600);
      expect(fallback.longitude, 31.6900);
      expect(fallback.isMapStartFallback, isTrue);
      expect(fallback.isDeviceDetected, isFalse);
      expect(
        () => CurrentLocationSuccess(fallback),
        throwsArgumentError,
      );
    });
  });
}
