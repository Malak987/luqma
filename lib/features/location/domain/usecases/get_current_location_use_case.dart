import '../entities/current_location_outcome.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocationUseCase {
  const GetCurrentLocationUseCase(this._repository);

  final LocationRepository _repository;

  Future<CurrentLocationOutcome> call() => _repository.getCurrentLocation();
}
