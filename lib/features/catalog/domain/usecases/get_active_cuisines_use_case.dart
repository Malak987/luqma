import '../entities/cuisine.dart';
import '../repositories/store_discovery_repository.dart';

class GetActiveCuisinesUseCase {
  const GetActiveCuisinesUseCase(this._repository);
  final StoreDiscoveryRepository _repository;

  Future<List<Cuisine>> call() async {
    final cuisines = (await _repository.getActiveCuisines())
        .where((cuisine) => cuisine.isActive)
        .toList(growable: false)
      ..sort((a, b) {
        final order = a.displayOrder.compareTo(b.displayOrder);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    return List<Cuisine>.unmodifiable(cuisines);
  }
}
