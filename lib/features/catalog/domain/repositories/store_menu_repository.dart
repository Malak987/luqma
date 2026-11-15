import '../entities/catalog_page.dart';
import '../entities/menu_category.dart';
import '../entities/menu_item.dart';
import '../queries/menu_item_query.dart';

abstract interface class StoreMenuRepository {
  Future<List<MenuCategory>> getActiveCategories(String storeId);
  Future<CatalogPage<MenuItem>> getItems(MenuItemQuery query);
}
