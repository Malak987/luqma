import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_menu_remote_data_source.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_menu_repository_impl.dart';
import 'package:luqma_app/features/catalog/data/repositories/cached_store_menu_repository.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_filters.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_query.dart';
import 'package:luqma_app/features/catalog/domain/repositories/store_menu_repository.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_state.dart';
import '../support/menu_fixtures.dart';

class Harness {
  final requests = <RequestOptions>[];
  bool fail = false;
  late final StoreMenuRepository raw;
  Harness() {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      requests.add(o);
      if (fail) {
        h.reject(DioException(
            requestOptions: o, type: DioExceptionType.connectionError));
        return;
      }
      final params = o.queryParameters;
      final store = params['storeId'] as String;
      final category = (params['menuCategoryId'] as String?) ?? menuCategoryId;
      final data = o.path.contains('MenuCategory')
          ? catalogEnvelope(data: [
              menuCategoryJson(store: store),
              menuCategoryJson(id: otherMenuCategoryId, store: store)
            ])
          : menuResponseJson(
              items: [menuItemJson(category: category)],
              number: params['pageNumber'] as int,
              pages: 2,
              next: params['pageNumber'] == 1);
      h.resolve(Response(requestOptions: o, statusCode: 200, data: data));
    }));
    raw = StoreMenuRepositoryImpl(StoreMenuRemoteDataSourceImpl(DioClient(
        SecureStorageService(const FlutterSecureStorage()),
        dio: dio)));
  }
  int get categories =>
      requests.where((r) => r.path == '/api/MenuCategory/GetAll').length;
  int get products =>
      requests.where((r) => r.path == '/api/MenuItem/GetAll').length;
}

StoreMenuCubit makeCubit(StoreMenuRepository repo, [String id = storeId]) =>
    StoreMenuCubit(
        storeId: id,
        getCategories: GetActiveMenuCategoriesUseCase(repo),
        getItems: GetMenuItemsUseCase(repo),
        paging: const CatalogPaging());

Future<void> visitTwice(StoreMenuRepository repo) async {
  for (var i = 0; i < 2; i++) {
    final c = makeCubit(repo);
    await c.load();
    await c.selectCategory(menuCategoryId);
    // Returning to All simulates navigating back from the category view.
    await c.selectCategory(null);
    expect(c.state.products.items.single.menuCategoryId, menuCategoryId);
    await c.close();
  }
}

void main() {
  test('measured before and after repeated visits and category return',
      () async {
    final before = Harness();
    await visitTwice(before.raw);
    final after = Harness();
    await visitTwice(CachedStoreMenuRepository(after.raw));
    expect([before.categories, before.products], [2, 6]);
    expect([after.categories, after.products], [1, 2]);
    // ignore: avoid_print
    print(
        'HTTP counts two visits: before categories=${before.categories} products=${before.products}; after categories=${after.categories} products=${after.products}');
  });
  test(
      'keys isolate store, category, all filters and pages; GET parameters unchanged',
      () async {
    final h = Harness();
    final repo = CachedStoreMenuRepository(h.raw);
    const base = MenuItemQuery(storeId: storeId, pageNumber: 1, pageSize: 20);
    final queries = [
      base,
      const MenuItemQuery(storeId: otherStoreId, pageNumber: 1, pageSize: 20),
      const MenuItemQuery(
          storeId: storeId,
          pageNumber: 1,
          pageSize: 20,
          filters: MenuItemFilters(menuCategoryId: otherMenuCategoryId)),
      const MenuItemQuery(
          storeId: storeId,
          pageNumber: 1,
          pageSize: 20,
          filters: MenuItemFilters(
              search: 'rice', minPrice: 2, maxPrice: 50, saleOnly: true)),
      const MenuItemQuery(storeId: storeId, pageNumber: 2, pageSize: 20),
      const MenuItemQuery(storeId: storeId, pageNumber: 1, pageSize: 10),
    ];
    for (final q in queries) {
      final p = await repo.getItems(q);
      expect(p.pageNumber, q.pageNumber);
    }
    for (final q in queries) {
      await repo.getItems(q);
    }
    expect(h.products, 6);
    expect(
        h.requests[2].queryParameters['menuCategoryId'], otherMenuCategoryId);
    expect(h.requests[3].queryParameters, {
      'storeId': storeId,
      'isActive': true,
      'pageNumber': 1,
      'pageSize': 20,
      'search': 'rice',
      'minPrice': 2,
      'maxPrice': 50,
      'onSale': true
    });
    await repo.getActiveCategories(storeId);
    await repo.getActiveCategories(otherStoreId);
    expect(h.categories, 2);
  });
  test('expired failed refresh retains matching data without full page loading',
      () async {
    var now = DateTime.utc(2026);
    final h = Harness();
    final repo = CachedStoreMenuRepository(h.raw, clock: () => now);
    final c = makeCubit(repo);
    await c.load();
    await c.close();
    now = now.add(const Duration(minutes: 3));
    h.fail = true;
    final next = makeCubit(repo);
    final changes = <StoreMenuState>[];
    final sub = next.stream.listen(changes.add);
    await next.load();
    await Future<void>.delayed(Duration.zero);
    expect(next.state.products.items.single.id, menuItemId);
    expect(next.state.products.failure, isNotNull);
    expect(next.state.products.stale, isTrue);
    expect(next.state.categories.items, isNotEmpty);
    expect(next.state.categories.failure, isNotNull);
    expect(next.state.categories.stale, isTrue);
    expect(
        changes.where((s) => s.products.status == MenuStatus.loading), isEmpty);
    expect([h.categories, h.products], [2, 2]);
    await sub.cancel();
    await next.close();
  });
  test('concurrent cubits share in-flight requests', () async {
    final h = Harness();
    final repo = CachedStoreMenuRepository(h.raw);
    final a = makeCubit(repo);
    final b = makeCubit(repo);
    await Future.wait([a.load(), b.load()]);
    expect([h.categories, h.products], [1, 1]);
    await a.close();
    await b.close();
  });
  test('failed refresh retains all previously appended pages', () async {
    var now = DateTime.utc(2026);
    final h = Harness();
    final repo = CachedStoreMenuRepository(h.raw, clock: () => now);
    final c = makeCubit(repo);
    await c.load();
    await c.loadNextPage();
    expect(c.state.products.pageNumber, 2);
    now = now.add(const Duration(minutes: 3));
    h.fail = true;
    await c.retryProducts();
    expect(c.state.products.pageNumber, 2);
    expect(c.state.products.items, isNotEmpty);
    expect(c.state.products.failure, isNotNull);
    expect(c.state.products.stale, isTrue);
    await c.close();
  });
}
