import '../entities/current_location_outcome.dart';

abstract interface class LocationRepository {
  /// Checks service and permission state, retrieving a position only when allowed.
  Future<CurrentLocationOutcome> getCurrentLocation();

  /// Requests foreground location permission according to [mode].
  Future<CurrentLocationOutcome> requestLocationPermission({
    required LocationPermissionRequestMode mode,
  });
}
