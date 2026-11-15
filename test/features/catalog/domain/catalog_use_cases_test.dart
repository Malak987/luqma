import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/domain/queries/store_query.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_cuisines_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_stores_use_case.dart';

import '../support/catalog_fixtures.dart';

void main() {
  test('active cuisines are sorted deterministically, bilingual and immutable',
      () async {
    final repository = FakeDiscoveryRepository()
      ..cuisines = [
        cuisine(id: otherCuisineId, order: 4),
        cuisine(order: 1),
        cuisine(id: testCatalogId(19), active: false, order: 0),
      ];
    final result = await GetActiveCuisinesUseCase(repository)();
    expect(result, [cuisine(), cuisine(id: otherCuisineId, order: 4)]);
    expect(repository.cuisines.length, 3);
    expect(() => result.clear(), throwsUnsupportedError);
  });

  test('valid StoreQuery is forwarded unchanged; metadata is never inferred',
      () async {
    final expected =
        storePage(items: [store()], number: 1, pages: 3, count: 42, next: true);
    final repository = FakeDiscoveryRepository()
      ..onStores = (_) async => expected;
    const query = StoreQuery(
        mainCategoryId: categoryId,
        cuisineId: cuisineId,
        openNowOnly: true,
        pageNumber: 1,
        pageSize: 20);
    expect(await GetStoresUseCase(repository)(query), same(expected));
    expect(repository.queries.single, same(query));
    expect(expected.hasNextPage, isTrue); // one item is not an end-of-list rule
  });

  test('invalid queries fail before reaching a repository', () async {
    final repository = FakeDiscoveryRepository();
    final useCase = GetStoresUseCase(repository);
    for (final query in [
      const StoreQuery(mainCategoryId: '', pageNumber: 1, pageSize: 20),
      const StoreQuery(
          mainCategoryId: categoryId,
          cuisineId: '',
          pageNumber: 1,
          pageSize: 20),
      const StoreQuery(
          mainCategoryId: categoryId, pageNumber: -1, pageSize: 20),
      const StoreQuery(mainCategoryId: categoryId, pageNumber: 1, pageSize: 0),
    ]) {
      await expectLater(
          useCase(query),
          throwsA(isA<FailureException>()
              .having((e) => e.failure.code, 'code', FailureCode.validation)));
    }
    expect(repository.queries, isEmpty);
  });

  test(
      'rejects incorrect page/scope/active/open data, not locally filtered totals',
      () async {
    final repository = FakeDiscoveryRepository();
    final useCase = GetStoresUseCase(repository);
    const query = StoreQuery(
        mainCategoryId: categoryId,
        openNowOnly: true,
        pageNumber: 1,
        pageSize: 20);
    for (final invalid in [
      storePage(number: 2),
      storePage(items: [store(category: testCatalogId(99))]),
      storePage(items: [store(active: false)]),
      storePage(items: [store(open: false)]),
    ]) {
      repository.onStores = (_) async => invalid;
      await expectLater(useCase(query), throwsA(isA<FailureException>()));
    }
  });

  test('failures propagate without infrastructure dependencies in the use case',
      () async {
    const failure = FailureException(Failure(FailureCode.network));
    final repository = FakeDiscoveryRepository();
    repository.onCuisines = () async => throw failure;
    repository.onStores = (_) async => throw failure;
    await expectLater(
        GetActiveCuisinesUseCase(repository)(), throwsA(same(failure)));
    await expectLater(
        GetStoresUseCase(repository)(const StoreQuery(
          mainCategoryId: categoryId,
          pageNumber: 1,
          pageSize: 20,
        )),
        throwsA(same(failure)));
  });
}
