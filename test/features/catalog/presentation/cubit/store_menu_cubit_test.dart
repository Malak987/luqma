import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:luqma_app/features/catalog/domain/entities/menu_category.dart';
import 'package:luqma_app/features/catalog/domain/entities/menu_item.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_filters.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_state.dart';

import '../../support/menu_fixtures.dart';

const _network = FailureException(Failure(FailureCode.network));

void main() {
  late FakeMenuRepository repository;
  late StoreMenuCubit cubit;

  StoreMenuCubit makeCubit(
          {String store = storeId,
          CatalogPaging paging = const CatalogPaging()}) =>
      StoreMenuCubit(
          storeId: store,
          getCategories: GetActiveMenuCategoriesUseCase(repository),
          getItems: GetMenuItemsUseCase(repository),
          paging: paging);

  setUp(() {
    repository = FakeMenuRepository()
      ..categories = [
        menuCategory(),
        menuCategory(id: otherMenuCategoryId, order: 2)
      ];
    cubit = makeCubit();
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test('initial filters are All, empty search/price bounds, sale OFF', () {
    expect(cubit.state.storeId, storeId);
    expect(cubit.state.filters, const MenuItemFilters());
    expect(cubit.state.categories.status, MenuStatus.initial);
    expect(cubit.state.products.status, MenuStatus.initial);
  });

  test(
      'entry loads categories and first All page independently, coalescing duplicate calls',
      () async {
    final categories = Completer<List<MenuCategory>>();
    final items = Completer<CatalogPage<MenuItem>>();
    repository.onCategories = (_) => categories.future;
    repository.onItems = (_) => items.future;
    final first = cubit.load();
    await cubit.load();
    await cubit.retryProducts();
    final categoryRetry = cubit.retryCategories();
    await pumpEventQueue();
    expect(repository.categoryStores, [storeId]);
    expect(repository.queries.length, 1);
    expect(repository.queries.single.filters.menuCategoryId, isNull);
    expect(cubit.state.categories.status, MenuStatus.loading);
    expect(cubit.state.products.status, MenuStatus.loading);
    items.complete(menuPage(items: [menuItem()]));
    await pumpEventQueue();
    expect(cubit.state.products.items, [menuItem()]);
    expect(cubit.state.categories.status, MenuStatus.loading);
    categories.complete([menuCategory()]);
    await Future.wait([first, categoryRetry]);
    await cubit.load();
    expect(repository.queries.length, 1);
  });

  test(
      'failed categories cannot hide products; categories retry is independent',
      () async {
    repository.onCategories = (_) async => throw _network;
    repository.onItems = (_) async => menuPage(items: [menuItem()]);
    await cubit.load();
    expect(cubit.state.categories.status, MenuStatus.failure);
    expect(cubit.state.products.items.length, 1);
    repository.onCategories = null;
    await cubit.retryCategories();
    expect(cubit.state.categories.status, MenuStatus.success);
    expect(repository.queries.length, 1);
  });

  test('failed products do not hide categories; product retry is independent',
      () async {
    repository.onItems = (_) async => throw _network;
    await cubit.load();
    expect(cubit.state.products.status, MenuStatus.failure);
    expect(cubit.state.categories.items.length, 2);
    repository.onItems = (_) async => menuPage();
    await cubit.retryProducts();
    expect(cubit.state.products.status, MenuStatus.empty);
    expect(repository.categoryStores.length, 1);
  });

  test('category counts never substitute for actual empty products', () async {
    await cubit.load();
    expect(cubit.state.categories.items.first.itemsCount, 99);
    expect(cubit.state.products.status, MenuStatus.empty);
    expect(cubit.state.products.items, isEmpty);
  });

  test(
      'all documented filters reset products and paging atomically and retain other filters',
      () async {
    repository.onItems = (q) async => menuPage(
        number: q.pageNumber,
        items: [menuItem(category: q.filters.menuCategoryId ?? menuCategoryId)],
        pages: 4,
        count: 70,
        next: true);
    await cubit.load();
    await cubit.loadNextPage();
    expect(cubit.state.products.pageNumber, 2);
    final states = <StoreMenuState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.selectCategory(menuCategoryId);
    await cubit.search('  rice  ');
    await cubit.setPriceRange(0, 50.5);
    await cubit.setSaleOnly(true);
    await cubit.loadNextPage();
    expect(repository.queries.last.pageNumber, 2);
    expect(
        repository.queries.last.filters,
        const MenuItemFilters(
            menuCategoryId: menuCategoryId,
            search: 'rice',
            minPrice: 0,
            maxPrice: 50.5,
            saleOnly: true));
    await cubit.selectCategory(null);
    expect(repository.queries.last.pageNumber, 1);
    expect(repository.queries.last.filters.menuCategoryId, isNull);
    expect(repository.queries.last.filters.search, 'rice');
    await cubit.search(' ');
    expect(cubit.state.filters.search, isNull);
    await cubit.setPriceRange(null, null);
    await cubit.setSaleOnly(false);
    await pumpEventQueue();
    for (final state
        in states.where((s) => s.products.status == MenuStatus.loading)) {
      expect(state.products.items, isEmpty);
      expect(state.products.pageNumber, isNull);
      expect(state.products.hasNextPage, isFalse);
      expect(state.products.nextPageFailure, isNull);
    }
    expect(repository.categoryStores.length, 1);
    await subscription.cancel();
  });

  test(
      'same/unknown/invalid selection and invalid price bounds never repeat requests',
      () async {
    await cubit.load();
    await cubit.selectCategory(menuCategoryId);
    final count = repository.queries.length;
    await cubit.selectCategory(menuCategoryId.toUpperCase());
    await cubit.selectCategory(testCatalogId(999));
    await cubit.selectCategory('');
    await cubit.search('   ');
    await cubit.setSaleOnly(false);
    await cubit.setPriceRange(-1, null);
    await cubit.setPriceRange(20, 10);
    await cubit.setPriceRange(double.nan, null);
    expect(repository.queries.length, count);
    expect(cubit.state.filters.menuCategoryId, menuCategoryId);
  });

  for (final staleError in [false, true]) {
    test('latest category wins over stale ${staleError ? 'error' : 'success'}',
        () async {
      await cubit.load();
      final a = Completer<CatalogPage<MenuItem>>();
      final b = Completer<CatalogPage<MenuItem>>();
      repository.onItems = (q) =>
          q.filters.menuCategoryId == menuCategoryId ? a.future : b.future;
      final first = cubit.selectCategory(menuCategoryId);
      final second = cubit.selectCategory(otherMenuCategoryId);
      b.complete(menuPage(items: [
        menuItem(id: otherMenuItemId, category: otherMenuCategoryId)
      ]));
      await second;
      if (staleError) {
        a.completeError(_network);
      } else {
        a.complete(menuPage(items: [menuItem()]));
      }
      await first;
      expect(cubit.state.filters.menuCategoryId, otherMenuCategoryId);
      expect(cubit.state.products.items.single.id, otherMenuItemId);
      expect(cubit.state.products.failure, isNull);
    });

    test(
        'filter reset ignores stale append ${staleError ? 'error' : 'success'}',
        () async {
      repository.onItems =
          (q) async => menuPage(items: [menuItem()], pages: 2, next: true);
      await cubit.load();
      final next = Completer<CatalogPage<MenuItem>>();
      repository.onItems = (q) => q.pageNumber == 2
          ? next.future
          : Future.value(menuPage(items: [menuItem(id: otherMenuItemId)]));
      final pending = cubit.loadNextPage();
      await cubit.search('new');
      if (staleError) {
        next.completeError(_network);
      } else {
        next.complete(menuPage(items: [menuItem()], number: 2, previous: true));
      }
      await pending;
      expect(cubit.state.filters.search, 'new');
      expect(cubit.state.products.items.single.id, otherMenuItemId);
      expect(cubit.state.products.pageNumber, 1);
      expect(cubit.state.products.nextPageFailure, isNull);
    });

    test(
        'A → B → A store context ignores old category/product ${staleError ? 'errors' : 'successes'}',
        () async {
      final categories = Completer<List<MenuCategory>>();
      final items = Completer<CatalogPage<MenuItem>>();
      var aCategoryCalls = 0;
      var aItemCalls = 0;
      repository.onCategories = (id) {
        if (id == storeId && aCategoryCalls++ == 0) return categories.future;
        return Future.value([menuCategory(store: id)]);
      };
      repository.onItems = (q) {
        if (q.storeId == storeId && aItemCalls++ == 0) return items.future;
        return Future.value(menuPage(items: [menuItem(id: otherMenuItemId)]));
      };
      final old = cubit.load();
      await cubit.changeStore(otherStoreId);
      await cubit.changeStore(storeId);
      if (staleError) {
        categories.completeError(_network);
        items.completeError(_network);
      } else {
        categories.complete([menuCategory()]);
        items.complete(menuPage(items: [menuItem()]));
      }
      await old;
      expect(repository.categoryStores, [storeId, otherStoreId, storeId]);
      expect(repository.queries.map((q) => q.storeId),
          [storeId, otherStoreId, storeId]);
      expect(cubit.state.storeId, storeId);
      expect(cubit.state.products.items.single.id, otherMenuItemId);
      expect(cubit.state.categories.status, MenuStatus.success);
      expect(cubit.state.products.failure, isNull);
    });
  }

  test(
      'append requests coalesce; case-insensitive dedupe retains order and updated snapshots',
      () async {
    repository.onItems = (_) async => menuPage(
        items: [menuItem(), menuItem(id: menuItemId.toUpperCase())],
        pages: 3,
        count: 40,
        next: true);
    await cubit.load();
    expect(cubit.state.products.items.length, 1);
    final pending = Completer<CatalogPage<MenuItem>>();
    repository.onItems = (_) => pending.future;
    final first = cubit.loadNextPage();
    await cubit.loadNextPage();
    await cubit.retryNextPage();
    expect(repository.queries.length, 2);
    pending.complete(menuPage(items: [
      menuItem(id: menuItemId.toUpperCase(), price: 19),
      menuItem(id: otherMenuItemId)
    ], number: 2, pages: 3, count: 40, next: true, previous: true));
    await first;
    expect(cubit.state.products.items.map((i) => i.id.toLowerCase()),
        [menuItemId, otherMenuItemId]);
    expect(cubit.state.products.items.first.price, 19);
    expect(cubit.state.products.pageNumber, 2);
    expect(cubit.state.products.totalCount, 40);
    expect(
        cubit.state.products.hasNextPage, isTrue); // short page is not the end
    repository.onItems = (q) async =>
        menuPage(number: q.pageNumber, pages: 3, count: 40, previous: true);
    await cubit.loadNextPage();
    await cubit.loadNextPage();
    expect(repository.queries.map((q) => q.pageNumber), [1, 2, 3]);
    expect(cubit.state.products.items.length, 2);
    expect(cubit.state.products.hasNextPage, isFalse);
  });

  test(
      'next-page failure retains list/index identity, metadata, and retries the same page explicitly',
      () async {
    repository.onItems = (_) async =>
        menuPage(items: [menuItem()], pages: 2, count: 25, next: true);
    await cubit.load();
    final items = cubit.state.products.items;
    final index = cubit.state.products.byId;
    repository.onItems = (_) async => throw _network;
    await cubit.loadNextPage();
    expect(cubit.state.products.items, same(items));
    expect(cubit.state.products.byId, same(index));
    expect(cubit.state.products.pageNumber, 1);
    expect(cubit.state.products.nextPageFailure?.code, FailureCode.network);
    await cubit.loadNextPage(); // no retry storm from scrolling
    expect(repository.queries.length, 2);
    repository.onItems = (q) async => menuPage(
        items: [menuItem(id: otherMenuItemId)],
        number: q.pageNumber,
        previous: true);
    await cubit.retryNextPage();
    expect(repository.queries.map((q) => q.pageNumber), [1, 2, 2]);
    expect(cubit.state.products.items.length, 2);
    expect(cubit.state.products.nextPageFailure, isNull);
  });

  test(
      'empty intermediate page continues only on metadata and empty final page is honest',
      () async {
    repository.onItems = (q) async =>
        menuPage(number: q.pageNumber, pages: 2, next: q.pageNumber == 1);
    await cubit.load();
    expect(cubit.state.products.status, MenuStatus.success);
    expect(cubit.state.products.hasNextPage, isTrue);
    await cubit.loadNextPage();
    expect(cubit.state.products.status, MenuStatus.empty);
    expect(cubit.state.products.hasNextPage, isFalse);
  });

  test('category refresh only resets products if the selected UUID was removed',
      () async {
    await cubit.load();
    await cubit.selectCategory(menuCategoryId);
    await cubit.retryCategories();
    expect(repository.queries.length, 2);
    repository.categories = [menuCategory(id: otherMenuCategoryId)];
    await cubit.retryCategories();
    expect(cubit.state.filters.menuCategoryId, isNull);
    expect(repository.queries.length, 3);
    expect(repository.queries.last.filters.menuCategoryId, isNull);
  });

  test('injected paging configuration is used without a guessed maximum',
      () async {
    await cubit.close();
    cubit = makeCubit(paging: const CatalogPaging(firstPage: 0, pageSize: 7));
    repository.onItems =
        (q) async => menuPage(number: q.pageNumber, next: q.pageNumber == 0);
    await cubit.load();
    await cubit.loadNextPage();
    expect(repository.queries.map((q) => q.pageNumber), [0, 1]);
    expect(repository.queries.every((q) => q.pageSize == 7), isTrue);
  });

  test('invalid store context fails locally before any data operation',
      () async {
    await cubit.close();
    cubit = makeCubit(store: 'bad');
    await cubit.load();
    expect(cubit.state.products.failure?.code, FailureCode.validation);
    expect(cubit.state.categories.status, MenuStatus.failure);
    expect(repository.queries, isEmpty);
    expect(repository.categoryStores, isEmpty);
  });

  test(
      'closed Cubit ignores an in-flight append without changing retained content',
      () async {
    repository.onItems =
        (_) async => menuPage(items: [menuItem()], next: true, pages: 2);
    await cubit.load();
    final next = Completer<CatalogPage<MenuItem>>();
    repository.onItems = (_) => next.future;
    final pending = cubit.loadNextPage();
    await cubit.close();
    final closedState = cubit.state;
    next.complete(menuPage(
        items: [menuItem(id: otherMenuItemId)], number: 2, previous: true));
    await pending;
    expect(cubit.state, same(closedState));
    expect(cubit.state.products.items.single.id, menuItemId);
  });

  for (final error in [false, true]) {
    test(
        'closed Cubit ignores pending initial ${error ? 'errors' : 'successes'} and later commands',
        () async {
      final categories = Completer<List<MenuCategory>>();
      final items = Completer<CatalogPage<MenuItem>>();
      repository.onCategories = (_) => categories.future;
      repository.onItems = (_) => items.future;
      final pending = cubit.load();
      await cubit.close();
      final closedState = cubit.state;
      if (error) {
        categories.completeError(_network);
        items.completeError(_network);
      } else {
        categories.complete([menuCategory()]);
        items.complete(menuPage(items: [menuItem()]));
      }
      await pending;
      await cubit.selectCategory(menuCategoryId);
      await cubit.search('ignored');
      await cubit.retryCategories();
      await cubit.retryProducts();
      await cubit.loadNextPage();
      await cubit.changeStore(otherStoreId);
      expect(cubit.state, same(closedState));
      expect(repository.queries.length, 1);
      expect(repository.categoryStores.length, 1);
    });
  }
}
