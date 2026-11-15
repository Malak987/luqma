import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_menu_remote_data_source.dart';
import 'package:luqma_app/features/catalog/data/models/menu_category_model.dart';
import 'package:luqma_app/features/catalog/data/models/menu_item_page_model.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_menu_repository_impl.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_filters.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_query.dart';

import '../support/menu_fixtures.dart';

const _query = MenuItemQuery(
    storeId: storeId,
    pageNumber: 2,
    pageSize: 8,
    filters: MenuItemFilters(
        menuCategoryId: menuCategoryId,
        search: 'dish',
        minPrice: 0,
        maxPrice: 50,
        saleOnly: true));

void main() {
  test(
      'maps complete GET snapshots and all metadata, forwarding real store/filter/page context',
      () async {
    final source = _Source();
    final repository = StoreMenuRepositoryImpl(source);
    final categories = await repository.getActiveCategories(storeId);
    expect(source.store, storeId);
    expect(categories, [menuCategory()]);
    expect(() => categories.clear(), throwsUnsupportedError);
    final page = await repository.getItems(_query);
    expect(source.query, same(_query));
    expect(page.items, [menuItem()]);
    expect([
      page.pageNumber,
      page.totalPages,
      page.totalCount,
      page.hasPreviousPage,
      page.hasNextPage
    ], [
      2,
      7,
      120,
      true,
      true
    ]);
    expect(() => page.items.clear(), throwsUnsupportedError);
  });

  for (final code in FailureCode.values) {
    test(
        'maps RemoteException $code in both operations without session behavior',
        () async {
      final repository = StoreMenuRepositoryImpl(_Source()
        ..error = RemoteException(code: code, message: 'Diagnostic'));
      for (final action in <Future<Object?> Function()>[
        () => repository.getActiveCategories(storeId),
        () => repository.getItems(_query),
      ]) {
        await expectLater(
            action(),
            throwsA(isA<FailureException>()
                .having((e) => e.failure.code, 'code', code)
                .having((e) => e.failure.debugMessage, 'diagnostic',
                    'Diagnostic')));
      }
    });
  }

  test('preserves domain failures and maps unexpected errors', () async {
    final source = _Source();
    final repository = StoreMenuRepositoryImpl(source);
    const error = FailureException(Failure(FailureCode.network));
    source.error = error;
    await expectLater(repository.getItems(_query), throwsA(same(error)));
    source.error = StateError('synthetic');
    await expectLater(
        repository.getActiveCategories(storeId),
        throwsA(isA<FailureException>()
            .having((e) => e.failure.code, 'code', FailureCode.unknown)));
  });
}

class _Source implements StoreMenuRemoteDataSource {
  Object? error;
  String? store;
  MenuItemQuery? query;
  @override
  Future<List<MenuCategoryModel>> getActiveCategories(String storeId) async {
    store = storeId;
    if (error != null) throw error!;
    return [MenuCategoryModel.fromJson(menuCategoryJson())];
  }

  @override
  Future<MenuItemPageModel> getItems(MenuItemQuery value) async {
    query = value;
    if (error != null) throw error!;
    return MenuItemPageModel.fromJson(menuResponseJson(
        items: [menuItemJson()],
        number: 2,
        pages: 7,
        count: 120,
        previous: true,
        next: true));
  }
}
