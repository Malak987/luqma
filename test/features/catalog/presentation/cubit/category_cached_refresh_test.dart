import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luqma_app/features/catalog/data/repositories/category_snapshot_cache_impl.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_state.dart';
import '../../support/menu_fixtures.dart';

void main() {
  test(
      'cached menu is visible during refresh and survives failure with retry state',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cache =
        CategorySnapshotCacheImpl(await SharedPreferences.getInstance());
    await cache.writeMenuCategories(storeId, [menuCategory()]);
    final response = Completer<List<dynamic>>();
    final repo = FakeMenuRepository()
      ..onCategories = (_) async => (await response.future).cast();
    final cubit = StoreMenuCubit(
        storeId: storeId,
        getCategories: GetActiveMenuCategoriesUseCase(repo),
        getItems: GetMenuItemsUseCase(repo),
        paging: const CatalogPaging(),
        categoryCache: cache);
    addTearDown(cubit.close);
    final load = cubit.load();
    expect(cubit.state.categories.items, [menuCategory()]);
    expect(cubit.state.categories.status, MenuStatus.success);
    response.completeError(Exception('offline'));
    await load;
    expect(cubit.state.categories.items, [menuCategory()]);
    expect(cubit.state.categories.failure, isNotNull);
    expect(cache.readMenuCategories(storeId), [menuCategory()]);
  });
}
