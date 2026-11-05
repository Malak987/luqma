import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/features/location/data/datasources/geolocator_location_data_source.dart';
import 'package:luqma_app/features/location/data/repositories/location_repository_impl.dart';
import 'package:luqma_app/features/location/domain/entities/current_location_outcome.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late PreferencesStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    storage = PreferencesStorageService(preferences);
  });

  group('LocationRepositoryImpl current-location checks', () {
    test('reports disabled services without checking permission or position',
        () async {
      final dataSource = _FakeLocationDataSource(serviceEnabled: false);
      final repository = _repository(dataSource, storage);

      expect(
        await repository.getCurrentLocation(),
        isA<LocationServiceDisabled>(),
      );
      expect(dataSource.checkPermissionCalls, 0);
      expect(dataSource.getCurrentPositionCalls, 0);
    });

    test('reports permission request required without prompting automatically',
        () async {
      final dataSource = _FakeLocationDataSource();
      final repository = _repository(dataSource, storage);

      expect(
        await repository.getCurrentLocation(),
        isA<LocationPermissionRequestRequired>(),
      );
      expect(dataSource.requestPermissionCalls, 0);
      expect(dataSource.getCurrentPositionCalls, 0);
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 0);
    });

    test('returns a successful device position when permission is granted',
        () async {
      final dataSource = _FakeLocationDataSource(
        permissionStatus: LocationPermissionStatus.granted,
      );
      final repository = _repository(dataSource, storage);

      final outcome = await repository.getCurrentLocation();

      expect(outcome, isA<CurrentLocationSuccess>());
      expect(
        (outcome as CurrentLocationSuccess).coordinates.isDeviceDetected,
        isTrue,
      );
      expect(dataSource.getCurrentPositionCalls, 1);
      expect(dataSource.requestPermissionCalls, 0);
    });

    test('distinguishes permanently denied permission', () async {
      final dataSource = _FakeLocationDataSource(
        permissionStatus: LocationPermissionStatus.permanentlyDenied,
      );
      final repository = _repository(dataSource, storage);

      expect(
        await repository.getCurrentLocation(),
        isA<LocationPermanentlyDenied>(),
      );
      expect(
        await repository.requestLocationPermission(
          mode: LocationPermissionRequestMode.explicit,
        ),
        isA<LocationPermanentlyDenied>(),
      );
      expect(dataSource.requestPermissionCalls, 0);
    });

    test('maps position retrieval failures to a typed failure outcome',
        () async {
      final dataSource = _FakeLocationDataSource(
        permissionStatus: LocationPermissionStatus.granted,
        positionFailure: const LocationDataSourceException(
          LocationDataSourceFailure.positionTimedOut,
        ),
      );
      final repository = _repository(dataSource, storage);

      final outcome = await repository.getCurrentLocation();

      expect(outcome, isA<LocationRetrievalFailure>());
      expect(
        (outcome as LocationRetrievalFailure).reason,
        LocationFailureReason.positionTimedOut,
      );
    });
  });

  group('LocationRepositoryImpl automatic permission policy', () {
    test('denial prevents a second automatic request in the same session',
        () async {
      final dataSource = _FakeLocationDataSource();
      final repository = _repository(dataSource, storage);

      expect(
        await repository.requestLocationPermission(
          mode: LocationPermissionRequestMode.automatic,
        ),
        isA<LocationPermissionDenied>(),
      );
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 1);

      expect(
        await repository.getCurrentLocation(),
        isA<LocationPermissionDenied>(),
      );
      expect(
        await repository.requestLocationPermission(
          mode: LocationPermissionRequestMode.automatic,
        ),
        isA<LocationPermissionDenied>(),
      );
      expect(dataSource.requestPermissionCalls, 1);
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 1);
    });

    test('allows a second automatic request in a later app session only',
        () async {
      final firstSessionSource = _FakeLocationDataSource();
      final firstSession = _repository(firstSessionSource, storage);
      await firstSession.requestLocationPermission(
        mode: LocationPermissionRequestMode.automatic,
      );
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 1);

      // A new repository represents the next app launch: the in-memory guard
      // resets, while the persisted counter is retained.
      final secondSessionSource = _FakeLocationDataSource();
      final secondSession = _repository(secondSessionSource, storage);
      expect(
        await secondSession.getCurrentLocation(),
        isA<LocationPermissionRequestRequired>(),
      );
      await secondSession.requestLocationPermission(
        mode: LocationPermissionRequestMode.automatic,
      );
      expect(secondSessionSource.requestPermissionCalls, 1);
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 2);

      final thirdSessionSource = _FakeLocationDataSource();
      final thirdSession = _repository(thirdSessionSource, storage);
      expect(
        await thirdSession.getCurrentLocation(),
        isA<LocationPermissionDenied>(),
      );
      expect(
        await thirdSession.requestLocationPermission(
          mode: LocationPermissionRequestMode.automatic,
        ),
        isA<LocationPermissionDenied>(),
      );
      expect(thirdSessionSource.requestPermissionCalls, 0);
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 2);
    });

    test('explicit retry bypasses the automatic budget and session guard',
        () async {
      final dataSource = _FakeLocationDataSource();
      final repository = _repository(dataSource, storage);

      await repository.requestLocationPermission(
        mode: LocationPermissionRequestMode.automatic,
      );
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 1);
      dataSource.requestedPermissionStatus = LocationPermissionStatus.granted;

      final retry = await repository.requestLocationPermission(
        mode: LocationPermissionRequestMode.explicit,
      );

      expect(retry, isA<CurrentLocationSuccess>());
      expect(dataSource.requestPermissionCalls, 2);
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 1);
    });

    test('explicit retry remains possible after the automatic cap', () async {
      await storage.recordLocationPermissionAutomaticAttempt();
      await storage.recordLocationPermissionAutomaticAttempt();
      final dataSource = _FakeLocationDataSource();
      final repository = _repository(dataSource, storage);

      expect(
        await repository.requestLocationPermission(
          mode: LocationPermissionRequestMode.automatic,
        ),
        isA<LocationPermissionDenied>(),
      );
      expect(dataSource.requestPermissionCalls, 0);

      await repository.requestLocationPermission(
        mode: LocationPermissionRequestMode.explicit,
      );
      expect(dataSource.requestPermissionCalls, 1);
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 2);
    });

    test('disabled services do not consume an automatic attempt', () async {
      final dataSource = _FakeLocationDataSource(serviceEnabled: false);
      final repository = _repository(dataSource, storage);

      expect(
        await repository.requestLocationPermission(
          mode: LocationPermissionRequestMode.automatic,
        ),
        isA<LocationServiceDisabled>(),
      );
      expect(dataSource.requestPermissionCalls, 0);
      expect(storage.getLocationPermissionAutomaticAttemptCount(), 0);
    });
  });
}

LocationRepositoryImpl _repository(
  LocationDataSource dataSource,
  PreferencesStorageService preferencesStorageService,
) {
  return LocationRepositoryImpl(
    dataSource: dataSource,
    preferencesStorageService: preferencesStorageService,
  );
}

class _FakeLocationDataSource implements LocationDataSource {
  _FakeLocationDataSource({
    this.serviceEnabled = true,
    this.permissionStatus = LocationPermissionStatus.denied,
    this.positionFailure,
    LocationCoordinates? currentPosition,
  }) : currentPosition = currentPosition ??
            LocationCoordinates.fromDevice(
              latitude: 40.7128,
              longitude: -74.0060,
            );

  final bool serviceEnabled;
  final LocationPermissionStatus permissionStatus;
  LocationPermissionStatus requestedPermissionStatus =
      LocationPermissionStatus.denied;
  final LocationDataSourceException? positionFailure;
  final LocationCoordinates currentPosition;

  int checkPermissionCalls = 0;
  int requestPermissionCalls = 0;
  int getCurrentPositionCalls = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    checkPermissionCalls++;
    return permissionStatus;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    requestPermissionCalls++;
    return requestedPermissionStatus;
  }

  @override
  Future<LocationCoordinates> getCurrentPosition() async {
    getCurrentPositionCalls++;
    if (positionFailure != null) {
      throw positionFailure!;
    }
    return currentPosition;
  }
}
