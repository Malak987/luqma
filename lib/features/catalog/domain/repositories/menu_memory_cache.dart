import '../entities/catalog_page.dart';
import '../entities/menu_category.dart';
import '../entities/menu_item.dart';
import '../queries/menu_item_query.dart';

class MenuCacheEntry<T> {
  const MenuCacheEntry(this.value, this.fresh);
  final T value;
  final bool fresh;
}

/// Optional synchronous view of the shared repository cache, including expired
/// snapshots so a failed refresh does not destroy previously visible data.
abstract interface class MenuMemoryCache {
  MenuCacheEntry<List<MenuCategory>>? categoriesSnapshot(String storeId);
  MenuCacheEntry<CatalogPage<MenuItem>>? itemsSnapshot(MenuItemQuery query);
}
