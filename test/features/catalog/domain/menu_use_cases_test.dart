import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_filters.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_query.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';

import '../support/menu_fixtures.dart';

void main() {
  test(
      'active categories sorted by displayOrder use real store IDs; counts stay metadata',
      () async {
    final repository = FakeMenuRepository()
      ..categories = [
        menuCategory(id: otherMenuCategoryId, order: 4),
        menuCategory(order: 1),
        menuCategory(id: testCatalogId(50), order: 0, active: false),
      ];
    final result = await GetActiveMenuCategoriesUseCase(repository)(storeId);
    expect(repository.categoryStores, [storeId]);
    expect(result.map((c) => c.id), [menuCategoryId, otherMenuCategoryId]);
    expect(result.first.itemsCount, 99);
    expect(() => result.clear(), throwsUnsupportedError);
    expect(repository.queries, isEmpty);
    await expectLater(GetActiveMenuCategoriesUseCase(repository)('bad'),
        throwsA(isA<FailureException>()));
    expect(repository.categoryStores.length, 1);
    repository.categories = [menuCategory(store: otherStoreId)];
    await expectLater(GetActiveMenuCategoriesUseCase(repository)(storeId),
        throwsA(isA<FailureException>()));
  });

  test(
      'forwards valid filters unchanged and retains authoritative short-page metadata',
      () async {
    final expected =
        menuPage(items: [menuItem()], pages: 5, count: 60, next: true);
    final repository = FakeMenuRepository()..onItems = (_) async => expected;
    const query = MenuItemQuery(
        storeId: storeId,
        pageNumber: 1,
        pageSize: 20,
        filters: MenuItemFilters(
            menuCategoryId: menuCategoryId,
            search: 'dish',
            minPrice: 0,
            maxPrice: 50,
            saleOnly: true));
    expect(await GetMenuItemsUseCase(repository)(query), same(expected));
    expect(repository.queries.single, same(query));
    expect(expected.hasNextPage, isTrue);
  });

  test(
      'invalid context, selected category, paging or price bounds never reach a repository',
      () async {
    final repository = FakeMenuRepository();
    final useCase = GetMenuItemsUseCase(repository);
    for (final query in [
      const MenuItemQuery(storeId: 'bad', pageNumber: 1, pageSize: 20),
      const MenuItemQuery(storeId: storeId, pageNumber: -1, pageSize: 20),
      const MenuItemQuery(storeId: storeId, pageNumber: 1, pageSize: 0),
      for (final filters in [
        const MenuItemFilters(menuCategoryId: ''),
        const MenuItemFilters(minPrice: -1),
        const MenuItemFilters(minPrice: 20, maxPrice: 10),
        const MenuItemFilters(maxPrice: double.infinity),
        const MenuItemFilters(minPrice: double.nan),
      ])
        MenuItemQuery(
            storeId: storeId, pageNumber: 1, pageSize: 20, filters: filters),
    ]) {
      await expectLater(
          useCase(query),
          throwsA(isA<FailureException>()
              .having((e) => e.failure.code, 'code', FailureCode.validation)));
    }
    expect(repository.queries, isEmpty);
  });

  test(
      'rejects mismatched page/category/inactive items rather than hiding corrupted totals',
      () async {
    final repository = FakeMenuRepository();
    const query = MenuItemQuery(
        storeId: storeId,
        pageNumber: 1,
        pageSize: 20,
        filters: MenuItemFilters(menuCategoryId: menuCategoryId));
    for (final page in [
      menuPage(number: 2),
      menuPage(items: [menuItem(category: otherMenuCategoryId)]),
      menuPage(items: [menuItem(active: false)])
    ]) {
      repository.onItems = (_) async => page;
      await expectLater(GetMenuItemsUseCase(repository)(query),
          throwsA(isA<FailureException>()));
    }
  });

  test('repository failures propagate with no infrastructure imports',
      () async {
    const error = FailureException(Failure(FailureCode.network));
    final repository = FakeMenuRepository()
      ..onCategories = ((_) async => throw error)
      ..onItems = (_) async => throw error;
    await expectLater(GetActiveMenuCategoriesUseCase(repository)(storeId),
        throwsA(same(error)));
    await expectLater(
        GetMenuItemsUseCase(repository)(
            const MenuItemQuery(storeId: storeId, pageNumber: 1, pageSize: 20)),
        throwsA(same(error)));
  });
}
