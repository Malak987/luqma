import '../../../../core/error/failures.dart';
import '../entities/catalog_page.dart';
import '../entities/store.dart';
import '../queries/catalog_identifiers.dart';
import '../queries/store_query.dart';
import '../repositories/store_discovery_repository.dart';

class GetStoresUseCase {
  const GetStoresUseCase(this._repository);
  final StoreDiscoveryRepository _repository;

  Future<CatalogPage<Store>> call(StoreQuery query) async {
    if (!isCatalogId(query.mainCategoryId) ||
        (query.cuisineId != null && !isCatalogId(query.cuisineId!)) ||
        query.pageNumber < 0 ||
        query.pageSize <= 0) {
      throw const FailureException(Failure(
        FailureCode.validation,
        debugMessage: 'Invalid customer store query',
      ));
    }
    final page = await _repository.getStores(query);
    // Never hide an invalid server page by locally filtering it and retaining
    // now-incorrect pagination totals. Report the contract violation instead.
    if (page.pageNumber != query.pageNumber ||
        page.items.any((store) =>
            store.mainCategoryId.toLowerCase() !=
                query.mainCategoryId.toLowerCase() ||
            !store.isActive ||
            (query.openNowOnly && !store.isOpenNow))) {
      throw const FailureException(Failure(
        FailureCode.unknown,
        debugMessage: 'Store page does not match the requested scope',
      ));
    }
    return page;
  }
}
