import '../repositories/store_details_repository.dart';

class GetStoreDetailsUseCase {
  const GetStoreDetailsUseCase(this.repository);
  final StoreDetailsRepository repository;
  StoreDetailsSnapshot? cached(String id, StoreDetailsLocation? location) =>
      repository.cached(id, location);
  Future<StoreDetailsSnapshot> call(String id,
          {StoreDetailsLocation? location, bool force = false}) =>
      repository.get(id, location: location, force: force);
}
