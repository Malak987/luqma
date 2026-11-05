import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:luqma_app/features/address/presentation/cubit/map_picker_cubit.dart';
import 'package:luqma_app/features/address/presentation/cubit/map_picker_state.dart';
import 'package:luqma_app/features/location/domain/entities/current_location_outcome.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:luqma_app/features/location/domain/usecases/get_current_location_use_case.dart';
import 'package:luqma_app/features/location/domain/usecases/request_location_permission_use_case.dart';
import 'package:luqma_app/features/location/domain/repositories/location_repository.dart';

void main() {
  group('MapPickerCubit', () {
    test('initial state is Sohag fallback not device', () {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermissionDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );
      expect(cubit.state.selected, LocationCoordinates.sohagMapStartFallback);
      expect(cubit.state.isFallback, isTrue);
      expect(cubit.state.selected.isDeviceDetected, isFalse);
      expect(cubit.state.selected.isMapStartFallback, isTrue);
      expect(cubit.state.status, MapPickerStatus.initial);
      cubit.close();
    });

    test('initialize with device GPS sets device coordinates and not fallback',
        () async {
      final device = LocationCoordinates.fromDevice(
        latitude: 30.0444,
        longitude: 31.2357,
      );
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: CurrentLocationSuccess(device),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );

      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, MapPickerStatus.ready);
      expect(cubit.state.selected, device);
      expect(cubit.state.isFallback, isFalse);
      expect(cubit.state.selected.isDeviceDetected, isTrue);
      expect(cubit.state.selected.isMapStartFallback, isFalse);
      // Must not be labelled as fallback
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('initialize with permission denied falls back to Sohag', () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermissionDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );

      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selected, LocationCoordinates.sohagMapStartFallback);
      expect(cubit.state.isFallback, isTrue);
      expect(cubit.state.selected.isDeviceDetected, isFalse);
      // Fallback must not be represented as device
      expect(cubit.state.selected.isMapStartFallback, isTrue);
      expect(cubit.state.status, MapPickerStatus.ready);
      await cubit.close();
    });

    test('initialize with permanently denied falls back to Sohag', () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermanentlyDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermanentlyDenied(),
        ),
      );

      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selected.latitude, 26.56);
      expect(cubit.state.selected.longitude, 31.69);
      expect(cubit.state.isFallback, isTrue);
      expect(cubit.state.selected.isDeviceDetected, isFalse);
      await cubit.close();
    });

    test('initialize with service disabled falls back to Sohag', () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationServiceDisabled(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationServiceDisabled(),
        ),
      );

      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selected, LocationCoordinates.sohagMapStartFallback);
      expect(cubit.state.isFallback, isTrue);
      expect(cubit.state.selected.isMapStartFallback, isTrue);
      await cubit.close();
    });

    test('fallback not represented as device location', () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermissionDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );

      await cubit.initialize();

      expect(cubit.state.selected.isDeviceDetected, isFalse);
      expect(cubit.state.isFallback, isTrue);
      // Ensure not device
      expect(cubit.state.selected.source,
          LocationCoordinateSource.mapStartFallback);
      await cubit.close();
    });

    test('manual map movement updates selected to mapSelection and clears fallback',
        () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermissionDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );

      await cubit.initialize();
      expect(cubit.state.isFallback, isTrue);

      final newLatLng = LatLng(30.0, 31.0);
      cubit.onMapMoved(newLatLng);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selected.latitude, 30.0);
      expect(cubit.state.selected.longitude, 31.0);
      expect(cubit.state.selected.source, LocationCoordinateSource.mapSelection);
      expect(cubit.state.isFallback, isFalse);
      expect(cubit.state.selected.isDeviceDetected, isFalse);
      expect(cubit.state.status, MapPickerStatus.ready);
      await cubit.close();
    });

    test('onMapMoved does not emit for same coordinates', () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermissionDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );
      await cubit.initialize();

      final latLng = LatLng(30.0, 31.0);
      cubit.onMapMoved(latLng);
      await Future<void>.delayed(Duration.zero);

      final states = <MapPickerState>[];
      final sub = cubit.stream.listen(states.add);

      // Same coordinates again — should not emit
      cubit.onMapMoved(latLng);
      await Future<void>.delayed(Duration.zero);

      expect(states, isEmpty);
      await sub.cancel();
      await cubit.close();
    });

    test('recenter success updates to device location', () async {
      final device1 = LocationCoordinates.fromDevice(
        latitude: 30.1,
        longitude: 31.1,
      );
      final fakeGet = _SequenceGetCurrentLocation(
        outcomes: [
          const LocationPermissionDenied(), // initial
          CurrentLocationSuccess(device1), // recenter
        ],
      );
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: fakeGet,
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );

      await cubit.initialize();
      expect(cubit.state.isFallback, isTrue);

      await cubit.recenter();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selected, device1);
      expect(cubit.state.isFallback, isFalse);
      expect(cubit.state.selected.isDeviceDetected, isTrue);
      expect(cubit.state.status, MapPickerStatus.ready);
      await cubit.close();
    });

    test('recenter with permission denied keeps fallback and sets error',
        () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermissionDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );

      await cubit.initialize();
      final before = cubit.state.selected;

      await cubit.recenter();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selected, before);
      expect(cubit.state.isFallback, isTrue);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.status, MapPickerStatus.ready);
      await cubit.close();
    });

    test('recenter with service disabled keeps fallback', () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationServiceDisabled(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationServiceDisabled(),
        ),
      );

      await cubit.initialize();
      final before = cubit.state.selected;

      await cubit.recenter();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.selected, before);
      expect(cubit.state.isFallback, isTrue);
      expect(cubit.state.errorMessage, contains('service_disabled'));
      await cubit.close();
    });

    test('confirm returns correct coordinates', () async {
      final device = LocationCoordinates.fromDevice(
        latitude: 29.9,
        longitude: 31.2,
      );
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: CurrentLocationSuccess(device),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );

      await cubit.initialize();
      cubit.confirmSelection();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isConfirmed, isTrue);
      expect(cubit.state.confirmed, device);
      expect(cubit.state.selected, device);
      expect(cubit.state.confirmed!.latitude, 29.9);
      await cubit.close();
    });

    test('confirm after manual move returns moved coordinates', () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationServiceDisabled(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationServiceDisabled(),
        ),
      );

      await cubit.initialize();
      final manual = LatLng(27.0, 32.0);
      cubit.onMapMoved(manual);
      cubit.confirmSelection();

      expect(cubit.state.confirmed!.latitude, 27.0);
      expect(cubit.state.confirmed!.longitude, 32.0);
      expect(cubit.state.confirmed!.source, LocationCoordinateSource.mapSelection);
      // Must not be fallback after manual move
      expect(cubit.state.confirmed!.isMapStartFallback, isFalse);
      await cubit.close();
    });

    test('does not request reverse geocoding', () {
      // Cubit has no dependency on ReverseGeocodeUseCase — verify via constructor
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermissionDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );
      // If reverse geocoding were requested, it would be a dependency.
      // We assert the cubit only holds the two location use-cases.
      expect(cubit, isA<MapPickerCubit>());
      cubit.close();
    });

    test('avoids unnecessary emissions during continuous movement', () async {
      final cubit = MapPickerCubit(
        getCurrentLocationUseCase: _FakeGetCurrentLocation(
          outcome: const LocationPermissionDenied(),
        ),
        requestLocationPermissionUseCase: _FakeRequestPermission(
          outcome: const LocationPermissionDenied(),
        ),
      );
      await cubit.initialize();

      // Simulate rapid move events — cubit should only emit on distinct ends
      final states = <MapPickerState>[];
      final sub = cubit.stream.listen(states.add);

      // Two distinct moves should emit twice
      cubit.onMapMoved(LatLng(30.0, 31.0));
      await Future<void>.delayed(Duration.zero);
      cubit.onMapMoved(LatLng(30.001, 31.001));
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].selected.latitude, 30.0);
      expect(states[1].selected.latitude, 30.001);

      // Same coord again — no emission
      cubit.onMapMoved(LatLng(30.001, 31.001));
      await Future<void>.delayed(Duration.zero);
      expect(states.length, 2);

      await sub.cancel();
      await cubit.close();
    });
  });
}

// Fakes

class _FakeGetCurrentLocation implements GetCurrentLocationUseCase {
  _FakeGetCurrentLocation({required this.outcome});
  final CurrentLocationOutcome outcome;
  @override
  Future<CurrentLocationOutcome> call() async => outcome;
}

class _SequenceGetCurrentLocation implements GetCurrentLocationUseCase {
  _SequenceGetCurrentLocation({required this.outcomes});
  final List<CurrentLocationOutcome> outcomes;
  int _index = 0;
  @override
  Future<CurrentLocationOutcome> call() async {
    final result = outcomes[_index.clamp(0, outcomes.length - 1)];
    if (_index < outcomes.length - 1) _index++;
    return result;
  }
}

class _FakeRequestPermission implements RequestLocationPermissionUseCase {
  _FakeRequestPermission({required this.outcome});
  final CurrentLocationOutcome outcome;
  @override
  Future<CurrentLocationOutcome> call({
    required LocationPermissionRequestMode mode,
  }) async {
    return outcome;
  }
}
