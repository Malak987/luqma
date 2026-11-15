import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/location/domain/entities/current_location_outcome.dart';
import 'package:luqma_app/features/location/domain/repositories/location_repository.dart';
import 'package:luqma_app/features/location/domain/usecases/get_current_location_use_case.dart';
import 'package:luqma_app/features/location/domain/usecases/request_location_permission_use_case.dart';

void main() {
  test('GetCurrentLocationUseCase forwards the repository outcome', () async {
    const outcome = LocationPermissionRequestRequired();
    final repository = _FakeLocationRepository(outcome);

    expect(await GetCurrentLocationUseCase(repository)(), same(outcome));
    expect(repository.getCurrentLocationCalls, 1);
  });

  test('RequestLocationPermissionUseCase forwards the explicit mode', () async {
    const outcome = LocationPermissionDenied();
    final repository = _FakeLocationRepository(outcome);

    expect(
      await RequestLocationPermissionUseCase(repository)(
        mode: LocationPermissionRequestMode.explicit,
      ),
      same(outcome),
    );
    expect(
      repository.requestModes,
      <LocationPermissionRequestMode>[LocationPermissionRequestMode.explicit],
    );
  });
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository(this.outcome);

  final CurrentLocationOutcome outcome;
  int getCurrentLocationCalls = 0;
  final List<LocationPermissionRequestMode> requestModes =
      <LocationPermissionRequestMode>[];

  @override
  Future<CurrentLocationOutcome> getCurrentLocation() async {
    getCurrentLocationCalls++;
    return outcome;
  }

  @override
  Future<CurrentLocationOutcome> requestLocationPermission({
    required LocationPermissionRequestMode mode,
  }) async {
    requestModes.add(mode);
    return outcome;
  }
}
