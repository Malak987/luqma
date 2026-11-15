import 'package:luqma_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:luqma_app/features/catalog/domain/entities/menu_category.dart';
import 'package:luqma_app/features/catalog/domain/entities/menu_item.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_query.dart';
import 'package:luqma_app/features/catalog/domain/repositories/store_menu_repository.dart';

import 'catalog_fixtures.dart';
export 'catalog_fixtures.dart';

// Synthetic values for the user-confirmed GET contract; never production data.
const menuCategoryId = '10000000-aaaa-4000-8000-000000000001';
const otherMenuCategoryId = '10000000-aaaa-4000-8000-000000000002';
const menuItemId = '10000000-bbbb-4000-8000-000000000100';
const otherMenuItemId = '10000000-bbbb-4000-8000-000000000101';
const optionId = '10000000-cccc-4000-8000-000000000200';
const addonId = '10000000-dddd-4000-8000-000000000201';

Map<String, Object?> menuCategoryJson(
        {String id = menuCategoryId,
        String store = storeId,
        int order = 1,
        int count = 99,
        bool active = true,
        String nameAr = 'أطباق رئيسية',
        String nameEn = 'Main dishes'}) =>
    {
      'id': id,
      'storeId': store,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'imageUrl': null,
      'displayOrder': order,
      'isActive': active,
      'itemsCount': count,
    };

Map<String, Object?> optionJson({String id = optionId}) => {
      'id': id,
      'nameAr': 'عادي',
      'nameEn': 'Regular',
      'price': 25.5,
    };
Map<String, Object?> addonJson({String id = addonId}) => {
      'id': id,
      'nameAr': 'جبن',
      'nameEn': 'Cheese',
      'price': 4,
      'imageUrl': null,
    };

Map<String, Object?> menuItemJson(
        {String id = menuItemId,
        String category = menuCategoryId,
        num price = 25.5,
        num compare = 30,
        bool soldByWeight = false,
        num? weight,
        bool active = true,
        Object? options = const [],
        Object? addons = const []}) =>
    {
      'id': id,
      'menuCategoryId': category,
      'menuCategoryNameAr': 'أطباق رئيسية',
      'menuCategoryNameEn': 'Main dishes',
      'nameAr': 'طبق النيل',
      'nameEn': 'Nile dish',
      'descriptionAr': 'وصف المنتج الحقيقي للاختبار',
      'descriptionEn': 'A synthetic product description',
      'price': price,
      'compareAtPrice': compare,
      'imageUrl': '',
      'isSoldByWeight': soldByWeight,
      'weight': weight,
      'isActive': active,
      'options': options,
      'addons': addons,
    };

Map<String, Object?> menuResponseJson(
        {List<Object?> items = const [],
        int number = 1,
        int pages = 1,
        int count = 0,
        bool previous = false,
        bool next = false}) =>
    catalogEnvelope(data: {
      'items': items,
      'pageNumber': number,
      'totalPages': pages,
      'totalCount': count,
      'hasPreviousPage': previous,
      'hasNextPage': next,
    });

MenuCategory menuCategory(
        {String id = menuCategoryId,
        String store = storeId,
        int order = 1,
        int count = 99,
        bool active = true,
        String nameAr = 'أطباق رئيسية',
        String nameEn = 'Main dishes'}) =>
    MenuCategory(
        id: id,
        storeId: store,
        nameAr: nameAr,
        nameEn: nameEn,
        displayOrder: order,
        isActive: active,
        itemsCount: count);

MenuItem menuItem(
        {String id = menuItemId,
        String category = menuCategoryId,
        String nameAr = 'طبق النيل',
        String nameEn = 'Nile dish',
        num price = 25.5,
        num compare = 30,
        bool active = true,
        bool soldByWeight = false,
        num? weight,
        String imageUrl = '',
        List<MenuItemOption> options = const [],
        List<MenuItemAddon> addons = const []}) =>
    MenuItem(
        id: id,
        menuCategoryId: category,
        menuCategoryNameAr: 'أطباق رئيسية',
        menuCategoryNameEn: 'Main dishes',
        nameAr: nameAr,
        nameEn: nameEn,
        descriptionAr: 'وصف المنتج الحقيقي للاختبار',
        descriptionEn: 'A synthetic product description',
        price: price,
        compareAtPrice: compare,
        imageUrl: imageUrl,
        isSoldByWeight: soldByWeight,
        weight: weight,
        isActive: active,
        options: options,
        addons: addons);

CatalogPage<MenuItem> menuPage(
        {List<MenuItem> items = const [],
        int number = 1,
        int pages = 1,
        int? count,
        bool previous = false,
        bool next = false}) =>
    CatalogPage<MenuItem>(
        items: items,
        pageNumber: number,
        totalPages: pages,
        totalCount: count ?? items.length,
        hasPreviousPage: previous,
        hasNextPage: next);

class FakeMenuRepository implements StoreMenuRepository {
  List<MenuCategory> categories = [];
  final List<String> categoryStores = [];
  final List<MenuItemQuery> queries = [];
  Future<List<MenuCategory>> Function(String storeId)? onCategories;
  Future<CatalogPage<MenuItem>> Function(MenuItemQuery query)? onItems;

  @override
  Future<List<MenuCategory>> getActiveCategories(String storeId) async {
    categoryStores.add(storeId);
    return onCategories == null ? categories : await onCategories!(storeId);
  }

  @override
  Future<CatalogPage<MenuItem>> getItems(MenuItemQuery query) async {
    queries.add(query);
    return onItems == null
        ? menuPage(number: query.pageNumber)
        : await onItems!(query);
  }
}
