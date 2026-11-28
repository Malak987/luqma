import '../repositories/menu_memory_cache.dart';
import '../../../../core/error/failures.dart';
import '../entities/catalog_page.dart';
import '../entities/menu_item.dart';
import '../queries/catalog_identifiers.dart';
import '../queries/menu_item_query.dart';
import '../repositories/store_menu_repository.dart';

class GetMenuItemsUseCase {
  const GetMenuItemsUseCase(this._repository);
  final StoreMenuRepository _repository;

  MenuCacheEntry<CatalogPage<MenuItem>>? snapshot(MenuItemQuery key) =>
      _repository is MenuMemoryCache
          ? (_repository as MenuMemoryCache).itemsSnapshot(key)
          : null;

  Future<CatalogPage<MenuItem>> call(MenuItemQuery query) async {
    final categoryId = query.filters.menuCategoryId;
    if (!isCatalogId(query.storeId) ||
        (categoryId != null && !isCatalogId(categoryId)) ||
        query.pageNumber < 0 ||
        query.pageSize <= 0 ||
        !query.filters.hasValidPrices) {
      throw const FailureException(Failure(FailureCode.validation,
          debugMessage: 'Invalid menu item query'));
    }
    final page = await _repository.getItems(query);
    // GET has no storeId on items: do not invent one. Store scope is sent on
    // every request; selected category and active/page consistency are checked.
    if (page.pageNumber != query.pageNumber ||
        page.items.any((item) =>
            !item.isActive ||
            (categoryId != null &&
                item.menuCategoryId.toLowerCase() !=
                    categoryId.toLowerCase()))) {
      throw const FailureException(Failure(FailureCode.unknown,
          debugMessage: 'Menu page does not match the requested scope'));
    }
    return page;
  }
}
