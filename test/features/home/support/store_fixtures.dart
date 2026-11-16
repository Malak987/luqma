import 'package:luqma_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:luqma_app/features/catalog/domain/entities/cuisine.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/queries/store_query.dart';
import 'package:luqma_app/features/catalog/domain/repositories/store_discovery_repository.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_stores_use_case.dart';

const testStore = Store(
  id: 'store-1',
  nameAr: 'مطعم النيل',
  nameEn: 'Nile Kitchen',
  mainCategoryId: '6f1c7b8e-1a2b-4c3d-8e4f-000000000001',
  isActive: true,
  isOpenNow: true,
  address: 'Sohag',
  mainCategoryNameAr: 'مطاعم',
  mainCategoryNameEn: 'Restaurants',
);

class FakeStoreDiscoveryRepository implements StoreDiscoveryRepository {
  List<Store> stores = const <Store>[];
  Object? error;
  int calls = 0;
  StoreQuery? lastQuery;
  Future<CatalogPage<Store>> Function(StoreQuery query)? pending;

  @override
  Future<CatalogPage<Store>> getStores(StoreQuery query) async {
    calls++;
    lastQuery = query;
    if (error != null) throw error!;
    if (pending != null) return pending!(query);
    return CatalogPage<Store>(
      items: stores,
      pageNumber: query.pageNumber,
      totalPages: stores.isEmpty ? 0 : 1,
      totalCount: stores.length,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }

  @override
  Future<List<Cuisine>> getActiveCuisines() async => const <Cuisine>[];
}

GetStoresUseCase testGetStoresUseCase() =>
    GetStoresUseCase(FakeStoreDiscoveryRepository());

class HomeStoreDependencies {
  HomeStoreDependencies({List<Store> stores = const <Store>[]}) {
    repository.stores = stores;
  }

  final FakeStoreDiscoveryRepository repository =
      FakeStoreDiscoveryRepository();
  GetStoresUseCase get useCase => GetStoresUseCase(repository);
  CatalogPaging get paging => const CatalogPaging(firstPage: 1, pageSize: 20);
}
