import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:luqma_app/features/catalog/domain/entities/cuisine.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_cuisines_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_stores_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_discovery_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_discovery_state.dart';

import '../../support/catalog_fixtures.dart';

const _network = FailureException(Failure(FailureCode.network));

void main() {
  late FakeDiscoveryRepository repository;
  late StoreDiscoveryCubit cubit;

  StoreDiscoveryCubit makeCubit(
          {String category = categoryId,
          CatalogPaging paging = const CatalogPaging()}) =>
      StoreDiscoveryCubit(
        mainCategoryId: category,
        getActiveCuisines: GetActiveCuisinesUseCase(repository),
        getStores: GetStoresUseCase(repository),
        paging: paging,
      );

  setUp(() {
    repository = FakeDiscoveryRepository()
      ..cuisines = [cuisine(), cuisine(id: otherCuisineId)];
    cubit = makeCubit();
  });
  tearDown(() async {
    await cubit.close();
  });

  test('initial states have All selected and Open Now OFF', () {
    expect(cubit.state.cuisines.status, CatalogStatus.initial);
    expect(cubit.state.stores.status, CatalogStatus.initial);
    expect(cubit.state.selectedCuisineId, isNull);
    expect(cubit.state.openNowOnly, isFalse);
  });

  test('loads both sections concurrently and coalesces duplicate initial calls',
      () async {
    final cuisines = Completer<List<Cuisine>>();
    final stores = Completer<CatalogPage<Store>>();
    repository.onCuisines = () => cuisines.future;
    repository.onStores = (_) => stores.future;
    final first = cubit.load();
    await cubit.load();
    await cubit.retryStores(); // the same in-flight first page is not repeated
    await pumpEventQueue();
    expect(repository.cuisineCalls, 1);
    expect(repository.queries.length, 1);
    expect(cubit.state.cuisines.status, CatalogStatus.loading);
    expect(cubit.state.stores.status, CatalogStatus.loading);
    stores.complete(storePage(items: [store()]));
    await pumpEventQueue();
    expect(cubit.state.stores.items, [store()]);
    expect(cubit.state.cuisines.status, CatalogStatus.loading);
    cuisines.complete([cuisine()]);
    await first;
    await cubit.load();
    expect(repository.queries.length, 1);
    expect(cubit.state.cuisines.status, CatalogStatus.success);
  });

  test('cuisine failure cannot hide stores and retry is section-local',
      () async {
    repository.onCuisines = () async => throw _network;
    repository.onStores = (_) async => storePage(items: [store()]);
    await cubit.load();
    expect(cubit.state.cuisines.status, CatalogStatus.failure);
    expect(cubit.state.stores.items, [store()]);
    repository.onCuisines = null;
    await cubit.retryCuisines();
    expect(cubit.state.cuisines.status, CatalogStatus.success);
    expect(repository.queries.length, 1);
    expect(repository.cuisineCalls, 2);
  });

  test('store failure cannot hide cuisines, and retry does not reload them',
      () async {
    repository.onStores = (_) async => throw _network;
    await cubit.load();
    expect(cubit.state.stores.status, CatalogStatus.failure);
    expect(cubit.state.cuisines.items.length, 2);
    repository.onStores = (_) async => storePage();
    await cubit.retryStores();
    expect(cubit.state.stores.status, CatalogStatus.empty);
    expect(repository.cuisineCalls, 1);
  });

  test('empty sections are not failures', () async {
    repository.cuisines = [];
    await cubit.load();
    expect(cubit.state.cuisines.status, CatalogStatus.empty);
    expect(cubit.state.stores.status, CatalogStatus.empty);
    expect(cubit.state.stores.failure, isNull);
  });

  test(
      'single-select filters restart only page one; same/unknown choice does nothing',
      () async {
    await cubit.load();
    await cubit.selectCuisine(cuisineId);
    expect(cubit.state.selectedCuisineId, cuisineId);
    expect(repository.queries.last.cuisineId, cuisineId);
    expect(repository.queries.last.pageNumber, 1);
    await cubit.selectCuisine(cuisineId);
    await cubit.selectCuisine(testCatalogId(909));
    await cubit.selectCuisine('');
    expect(repository.queries.length, 2);
    await cubit.setOpenNowOnly(true);
    expect(repository.queries.last.openNowOnly, isTrue);
    expect(repository.queries.last.cuisineId, cuisineId);
    await cubit.setOpenNowOnly(true);
    expect(repository.queries.length, 3);
    await cubit.selectCuisine(null);
    expect(repository.queries.last.cuisineId, isNull);
    await cubit.setOpenNowOnly(false);
    expect(repository.queries.last.openNowOnly, isFalse);
    expect(repository.cuisineCalls, 1);
  });

  test('clearing no active filters does not reload stores', () async {
    await cubit.load();
    final stateBeforeClear = cubit.state;
    final queryCount = repository.queries.length;
    final emittedStates = <StoreDiscoveryState>[];
    final subscription = cubit.stream.listen(emittedStates.add);

    await cubit.clearAllFilters();

    expect(repository.queries, hasLength(queryCount));
    expect(emittedStates, isEmpty);
    expect(cubit.state, same(stateBeforeClear));
    await subscription.cancel();
  });

  test('clearing one active filter makes one first-page request', () async {
    await cubit.load();
    await cubit.selectCuisine(cuisineId);
    final queryCount = repository.queries.length;

    await cubit.clearAllFilters();

    expect(repository.queries, hasLength(queryCount + 1));
    expect(repository.queries.last.cuisineId, isNull);
    expect(repository.queries.last.openNowOnly, isFalse);
    expect(repository.queries.last.pageNumber, 1);
    expect(cubit.state.selectedCuisineId, isNull);
    expect(cubit.state.openNowOnly, isFalse);
  });

  test('clearing both filters makes one request and resets pagination',
      () async {
    repository.onStores = (query) async => storePage(
          number: query.pageNumber,
          pages: 3,
          count: 30,
          next: query.pageNumber < 3,
        );
    await cubit.load();
    await cubit.loadNextPage();
    await cubit.selectCuisine(cuisineId);
    await cubit.setOpenNowOnly(true);
    await cubit.loadNextPage();
    expect(cubit.state.stores.pageNumber, 2);
    expect(cubit.state.stores.hasNextPage, isTrue);

    final queryCount = repository.queries.length;
    await cubit.clearAllFilters();

    expect(repository.queries, hasLength(queryCount + 1));
    expect(repository.queries.last.cuisineId, isNull);
    expect(repository.queries.last.openNowOnly, isFalse);
    expect(repository.queries.last.pageNumber, 1);
    expect(cubit.state.selectedCuisineId, isNull);
    expect(cubit.state.openNowOnly, isFalse);
    expect(cubit.state.stores.pageNumber, 1);
    expect(cubit.state.stores.totalPages, 3);
    expect(cubit.state.stores.totalCount, 30);
    expect(cubit.state.stores.hasNextPage, isTrue);
    expect(cubit.state.stores.isLoadingMore, isFalse);
    expect(cubit.state.stores.nextPageFailure, isNull);
  });

  test('clearing filters prevents stale in-flight responses from winning',
      () async {
    await cubit.load();
    await cubit.selectCuisine(cuisineId);
    final stale = Completer<CatalogPage<Store>>();
    repository.onStores = (query) => query.openNowOnly
        ? stale.future
        : Future.value(storePage(items: [
            store(id: otherStoreId),
          ]));
    final olderRequest = cubit.setOpenNowOnly(true);
    await pumpEventQueue();
    final queryCount = repository.queries.length;

    await cubit.clearAllFilters();
    stale.complete(storePage(items: [store()]));
    await olderRequest;

    expect(repository.queries, hasLength(queryCount + 1));
    expect(cubit.state.selectedCuisineId, isNull);
    expect(cubit.state.openNowOnly, isFalse);
    expect(cubit.state.stores.items.single.id, otherStoreId);
    expect(cubit.state.stores.failure, isNull);
  });

  for (final staleError in [false, true]) {
    test('latest cuisine wins over a stale ${staleError ? 'error' : 'success'}',
        () async {
      await cubit.load();
      final first = Completer<CatalogPage<Store>>();
      final second = Completer<CatalogPage<Store>>();
      repository.onStores = (query) =>
          query.cuisineId == cuisineId ? first.future : second.future;
      final a = cubit.selectCuisine(cuisineId);
      final b = cubit.selectCuisine(otherCuisineId);
      await pumpEventQueue();
      second.complete(storePage(items: [store(id: otherStoreId)]));
      await b;
      if (staleError) {
        first.completeError(_network);
      } else {
        first.complete(storePage(items: [store()]));
      }
      await a;
      expect(cubit.state.selectedCuisineId, otherCuisineId);
      expect(cubit.state.stores.items.single.id, otherStoreId);
      expect(cubit.state.stores.failure, isNull);
    });
  }

  test('old successful response cannot overwrite a newer filter failure',
      () async {
    await cubit.load();
    final old = Completer<CatalogPage<Store>>();
    repository.onStores = (query) => query.openNowOnly
        ? Future<CatalogPage<Store>>.error(_network)
        : old.future;
    final older = cubit.selectCuisine(cuisineId);
    await cubit.setOpenNowOnly(true);
    old.complete(storePage(items: [store()]));
    await older;
    expect(cubit.state.openNowOnly, isTrue);
    expect(cubit.state.stores.status, CatalogStatus.failure);
    expect(cubit.state.stores.items, isEmpty);
  });

  test('hasNextPage alone controls appending; duplicate loads are coalesced',
      () async {
    repository.onStores =
        (_) async => storePage(items: [store()], pages: 3, next: true);
    await cubit.load();
    final pending = Completer<CatalogPage<Store>>();
    repository.onStores = (_) => pending.future;
    final items = cubit.state.stores.items;
    final next = cubit.loadNextPage();
    await cubit.loadNextPage();
    expect(repository.queries.length, 2);
    expect(repository.queries.last.pageNumber, 2);
    expect(cubit.state.stores.isLoadingMore, isTrue);
    expect(cubit.state.stores.items, same(items));
    pending.complete(storePage(
        items: [store(id: otherStoreId)], number: 2, pages: 3, next: false));
    await next;
    expect(cubit.state.stores.items.map((item) => item.id),
        [storeId, otherStoreId]);
    expect(cubit.state.stores.pageNumber, 2);
    await cubit.loadNextPage();
    expect(repository.queries.length, 2);
  });

  test('ID deduplication keeps order and updates repeated snapshots', () async {
    const mixedId = 'a1234567-abcd-4abc-8def-123456789012';
    repository.onStores = (_) async =>
        storePage(items: [store(id: mixedId), store()], next: true);
    await cubit.load();
    repository.onStores = (_) async => storePage(number: 2, items: [
          store(id: mixedId.toUpperCase(), nameEn: 'Updated'),
          store(id: otherStoreId),
          store(id: otherStoreId),
        ]);
    await cubit.loadNextPage();
    expect(cubit.state.stores.items.length, 3);
    expect(cubit.state.stores.items.first.nameEn, 'Updated');
    expect(cubit.state.stores.items[1].id, storeId);
    expect(cubit.state.stores.items.last.id, otherStoreId);
  });

  test(
      'append errors retain data/page; explicit retry requests the same next page',
      () async {
    repository.onStores = (_) async => storePage(items: [store()], next: true);
    await cubit.load();
    final items = cubit.state.stores.items;
    repository.onStores = (_) async => throw _network;
    await cubit.loadNextPage();
    expect(cubit.state.stores.items, same(items));
    expect(cubit.state.stores.pageNumber, 1);
    expect(cubit.state.stores.status, CatalogStatus.success);
    expect(cubit.state.stores.nextPageFailure?.code, FailureCode.network);
    expect(cubit.state.stores.isLoadingMore, isFalse);
    await cubit
        .loadNextPage(); // scrolling must not spin repeated failed requests
    expect(repository.queries.length, 2);
    repository.onStores =
        (_) async => storePage(number: 2, items: [store(id: otherStoreId)]);
    await cubit.retryNextPage();
    expect(repository.queries.map((query) => query.pageNumber), [1, 2, 2]);
    expect(cubit.state.stores.nextPageFailure, isNull);
    expect(cubit.state.stores.items.length, 2);
  });

  for (final staleError in [false, true]) {
    test(
        'filter change invalidates an in-flight append ${staleError ? 'error' : 'success'}',
        () async {
      repository.onStores =
          (_) async => storePage(items: [store()], next: true);
      await cubit.load();
      final pending = Completer<CatalogPage<Store>>();
      repository.onStores = (query) => query.pageNumber == 2
          ? pending.future
          : Future.value(storePage(items: [store(id: otherStoreId)]));
      final append = cubit.loadNextPage();
      await cubit.setOpenNowOnly(true);
      if (staleError) {
        pending.completeError(_network);
      } else {
        pending.complete(storePage(number: 2, items: [store()]));
      }
      await append;
      expect(cubit.state.stores.items.single.id, otherStoreId);
      expect(cubit.state.stores.pageNumber, 1);
      expect(cubit.state.stores.isLoadingMore, isFalse);
      expect(cubit.state.stores.nextPageFailure, isNull);
    });
  }

  test('empty page with hasNext=true remains pageable; no short-page heuristic',
      () async {
    repository.onStores =
        (_) async => storePage(next: true, pages: 2, count: 1);
    await cubit.load();
    expect(cubit.state.stores.status, CatalogStatus.success);
    repository.onStores = (_) async => storePage(number: 2, items: [store()]);
    await cubit.loadNextPage();
    expect(cubit.state.stores.items.single.id, storeId);
  });

  test('an empty final continuation produces an honest empty state', () async {
    repository.onStores = (_) async => storePage(next: true);
    await cubit.load();
    repository.onStores = (_) async => storePage(number: 2);
    await cubit.loadNextPage();
    expect(cubit.state.stores.status, CatalogStatus.empty);
    expect(cubit.state.stores.items, isEmpty);
    expect(cubit.state.stores.hasNextPage, isFalse);
  });

  test('full page with hasNext=false never requests another page', () async {
    repository.onStores = (_) async => storePage(
        items:
            List.generate(20, (index) => store(id: testCatalogId(index + 20))));
    await cubit.load();
    await cubit.loadNextPage();
    expect(repository.queries.length, 1);
  });

  test(
      'a selected cuisine removed by metadata refresh resets to All exactly once',
      () async {
    await cubit.load();
    await cubit.selectCuisine(cuisineId);
    repository.cuisines = [];
    await cubit.refresh();
    expect(cubit.state.selectedCuisineId, isNull);
    expect(cubit.state.cuisines.status, CatalogStatus.empty);
    expect(repository.queries.length, 3);
    expect(repository.queries.last.cuisineId, isNull);
  });

  test('paging settings are injected, not a verified backend limit', () async {
    await cubit.close();
    cubit = makeCubit(paging: const CatalogPaging(firstPage: 0, pageSize: 7));
    await cubit.load();
    expect(repository.queries.single.pageNumber, 0);
    expect(repository.queries.single.pageSize, 7);
  });

  test('invalid category fails without either browsing request', () async {
    await cubit.close();
    cubit = makeCubit(category: 'invalid');
    await cubit.load();
    await cubit.retryCuisines();
    expect(repository.cuisineCalls, 0);
    expect(repository.queries, isEmpty);
    expect(cubit.state.stores.failure?.code, FailureCode.validation);
  });

  test('late responses after close cannot emit or throw', () async {
    final pending = Completer<CatalogPage<Store>>();
    repository.onStores = (_) => pending.future;
    final loading = cubit.load();
    await cubit.close();
    pending.completeError(_network);
    await loading;
    expect(cubit.isClosed, isTrue);
  });

  test('unknown errors are mapped and all exposed collections are immutable',
      () async {
    repository.onStores = (_) async => throw StateError('internal ID $storeId');
    await cubit.load();
    expect(cubit.state.stores.failure?.code, FailureCode.unknown);
    expect(cubit.state.stores.failure?.debugMessage, isNull);
    expect(() => cubit.state.cuisines.items.clear(), throwsUnsupportedError);
    expect(() => cubit.state.stores.items.clear(), throwsUnsupportedError);
  });
}
