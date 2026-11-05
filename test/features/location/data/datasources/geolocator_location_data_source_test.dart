import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:luqma_app/features/location/data/datasources/geolocator_location_data_source.dart';
import 'package:luqma_app/features/location/domain/entities/current_location_outcome.dart';

void main() {
  group('GeolocatorLocationDataSource.mapPermission', () {
    test('maps foreground and always-granted states to granted', () {
      expect(
        GeolocatorLocationDataSource.mapPermission(
          LocationPermission.whileInUse,
        ),
        LocationPermissionStatus.granted,
      );
      expect(
        GeolocatorLocationDataSource.mapPermission(LocationPermission.always),
        LocationPermissionStatus.granted,
      );
    });

    test('keeps ordinary and permanent denial distinct', () {
      expect(
        GeolocatorLocationDataSource.mapPermission(LocationPermission.denied),
        LocationPermissionStatus.denied,
      );
      expect(
        GeolocatorLocationDataSource.mapPermission(
          LocationPermission.deniedForever,
        ),
        LocationPermissionStatus.permanentlyDenied,
      );
    });

    test('maps an undetermined platform result to unknown', () {
      expect(
        GeolocatorLocationDataSource.mapPermission(
          LocationPermission.unableToDetermine,
        ),
        LocationPermissionStatus.unknown,
      );
    });
  });
}
