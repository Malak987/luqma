import '../entities/catalog_page.dart';
import '../entities/cuisine.dart';
import '../entities/store.dart';
import '../queries/store_query.dart';

abstract interface class StoreDiscoveryRepository {
  Future<List<Cuisine>> getActiveCuisines();
  Future<CatalogPage<Store>> getStores(StoreQuery query);
}
