import '../entities/current_location_outcome.dart';
import '../repositories/location_repository.dart';

class RequestLocationPermissionUseCase {
  const RequestLocationPermissionUseCase(this._repository);

  final LocationRepository _repository;

  Future<CurrentLocationOutcome> call({
    required LocationPermissionRequestMode mode,
  }) {
    return _repository.requestLocationPermission(mode: mode);
  }
}
