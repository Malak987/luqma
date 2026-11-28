import '../repositories/menu_memory_cache.dart';
import '../../../../core/error/failures.dart';
import '../entities/menu_category.dart';
import '../queries/catalog_identifiers.dart';
import '../repositories/store_menu_repository.dart';

class GetActiveMenuCategoriesUseCase {
  const GetActiveMenuCategoriesUseCase(this._repository);
  final StoreMenuRepository _repository;

  MenuCacheEntry<List<MenuCategory>>? snapshot(String key) =>
      _repository is MenuMemoryCache
          ? (_repository as MenuMemoryCache).categoriesSnapshot(key)
          : null;

  Future<List<MenuCategory>> call(String storeId) async {
    if (!isCatalogId(storeId)) {
      throw const FailureException(Failure(FailureCode.validation,
          debugMessage: 'Invalid menu store context'));
    }
    final categories = await _repository.getActiveCategories(storeId);
    if (categories.any((category) =>
        category.storeId.toLowerCase() != storeId.toLowerCase())) {
      throw const FailureException(Failure(FailureCode.unknown,
          debugMessage: 'Menu categories do not match the requested store'));
    }
    final active = <String, MenuCategory>{
      for (final category in categories)
        if (category.isActive) category.id.toLowerCase(): category,
    }.values.toList(growable: false)
      ..sort((a, b) {
        final order = a.displayOrder.compareTo(b.displayOrder);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    return List<MenuCategory>.unmodifiable(active);
  }
}
