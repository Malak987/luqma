import 'package:luqma_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:luqma_app/features/catalog/domain/entities/cuisine.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/catalog/domain/queries/store_query.dart';
import 'package:luqma_app/features/catalog/domain/repositories/store_discovery_repository.dart';

// Synthetic test values for the user-documented fields, NOT captured API data.
const categoryId = '00000000-0000-4000-8000-000000000001';
const cuisineId = '00000000-0000-4000-8000-000000000002';
const otherCuisineId = '00000000-0000-4000-8000-000000000003';
const storeId = '00000000-0000-4000-8000-000000000004';
const otherStoreId = '00000000-0000-4000-8000-000000000005';

String testCatalogId(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';

Map<String, Object?> catalogEnvelope(
        {required Object? data,
        bool succeeded = true,
        String message = 'Synthetic test response'}) =>
    {
      'message': message,
      'data': data,
      'isSucceeded': succeeded,
      'timestamp': '2026-11-14T12:00:00Z',
    };

Map<String, Object?> cuisineJson(
        {String id = cuisineId,
        int order = 1,
        bool active = true,
        String? imageUrl}) =>
    {
      'id': id,
      'nameAr': 'إيطالي',
      'nameEn': 'Italian',
      'imageUrl': imageUrl,
      'displayOrder': order,
      'isActive': active,
    };

Map<String, Object?> storeJson(
        {String id = storeId,
        String category = categoryId,
        bool open = true,
        bool active = true,
        String? iconUrl,
        String? address = 'Sohag'}) =>
    {
      'id': id,
      'nameAr': 'مطعم النيل',
      'nameEn': 'Nile Kitchen',
      'mainCategoryId': category,
      'iconUrl': iconUrl,
      'address': address,
      'isActive': active,
      'isOpenNow': open,
    };

Map<String, Object?> storePageJson(
        {List<Object?> items = const [],
        int number = 1,
        int pages = 1,
        int count = 0,
        bool previous = false,
        bool next = false}) =>
    {
      'items': items,
      'pageNumber': number,
      'totalPages': pages,
      'totalCount': count,
      'hasPreviousPage': previous,
      'hasNextPage': next,
    };

Map<String, Object?> storeResponseJson({
  List<Object?> items = const [],
  int number = 1,
  int pages = 1,
  int count = 0,
  bool previous = false,
  bool next = false,
}) =>
    catalogEnvelope(
        data: storePageJson(
            items: items,
            number: number,
            pages: pages,
            count: count,
            previous: previous,
            next: next));

Cuisine cuisine(
        {String id = cuisineId,
        String nameAr = 'إيطالي',
        String nameEn = 'Italian',
        int order = 1,
        bool active = true}) =>
    Cuisine(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      displayOrder: order,
      isActive: active,
    );

Store store(
        {String id = storeId,
        String category = categoryId,
        String nameAr = 'مطعم النيل',
        String nameEn = 'Nile Kitchen',
        bool open = true,
        bool active = true,
        String? iconUrl,
        String? address = 'Sohag',
        String? phoneNumber,
        String? categoryNameAr,
        String? categoryNameEn}) =>
    Store(
      id: id,
      mainCategoryId: category,
      nameAr: nameAr,
      nameEn: nameEn,
      isActive: active,
      isOpenNow: open,
      iconUrl: iconUrl,
      address: address,
      phoneNumber: phoneNumber,
      mainCategoryNameAr: categoryNameAr,
      mainCategoryNameEn: categoryNameEn,
    );

CatalogPage<Store> storePage(
        {List<Store> items = const [],
        int number = 1,
        int pages = 1,
        int? count,
        bool previous = false,
        bool next = false}) =>
    CatalogPage<Store>(
        items: items,
        pageNumber: number,
        totalPages: pages,
        totalCount: count ?? items.length,
        hasPreviousPage: previous,
        hasNextPage: next);

class FakeDiscoveryRepository implements StoreDiscoveryRepository {
  List<Cuisine> cuisines = [];
  int cuisineCalls = 0;
  final List<StoreQuery> queries = [];
  Future<List<Cuisine>> Function()? onCuisines;
  Future<CatalogPage<Store>> Function(StoreQuery)? onStores;

  @override
  Future<List<Cuisine>> getActiveCuisines() async {
    cuisineCalls++;
    return onCuisines == null ? cuisines : await onCuisines!();
  }

  @override
  Future<CatalogPage<Store>> getStores(StoreQuery query) async {
    queries.add(query);
    return onStores == null
        ? storePage(number: query.pageNumber)
        : await onStores!(query);
  }
}
