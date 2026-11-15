import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_discovery_remote_data_source.dart';
import 'package:luqma_app/features/catalog/data/models/cuisine_model.dart';
import 'package:luqma_app/features/catalog/data/models/store_page_model.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_discovery_repository_impl.dart';
import 'package:luqma_app/features/catalog/domain/queries/store_query.dart';

import '../support/catalog_fixtures.dart';

const _query =
    StoreQuery(mainCategoryId: categoryId, pageNumber: 2, pageSize: 20);

void main() {
  test('maps both names and all paging metadata to pure domain values',
      () async {
    final source = _Source();
    final repository = StoreDiscoveryRepositoryImpl(source);
    expect(await repository.getActiveCuisines(), [cuisine()]);
    final page = await repository.getStores(_query);
    expect(source.query, same(_query));
    expect(page.items, [store()]);
    expect(page.pageNumber, 2);
    expect(page.totalPages, 7);
    expect(page.totalCount, 130);
    expect(page.hasPreviousPage, isTrue);
    expect(page.hasNextPage, isTrue);
    expect(() => page.items.clear(), throwsUnsupportedError);
    final cuisines = await repository.getActiveCuisines();
    expect(() => cuisines.clear(), throwsUnsupportedError);
  });

  for (final code in FailureCode.values) {
    test(
        'maps RemoteException $code consistently in both repository operations',
        () async {
      final repository = StoreDiscoveryRepositoryImpl(_Source()
        ..error = RemoteException(code: code, message: 'Synthetic diagnostic'));
      for (final action in <Future<Object?> Function()>[
        repository.getActiveCuisines,
        () => repository.getStores(_query),
      ]) {
        await expectLater(
            action(),
            throwsA(isA<FailureException>()
                .having((e) => e.failure.code, 'code', code)
                .having((e) => e.failure.debugMessage, 'diagnostic',
                    'Synthetic diagnostic')));
      }
    });
  }

  test('preserves domain failures and converts unexpected errors', () async {
    final source = _Source();
    final repository = StoreDiscoveryRepositoryImpl(source);
    const failure = FailureException(Failure(FailureCode.network));
    source.error = failure;
    await expectLater(repository.getStores(_query), throwsA(same(failure)));
    source.error = StateError('bad response');
    await expectLater(
        repository.getActiveCuisines(),
        throwsA(isA<FailureException>()
            .having((e) => e.failure.code, 'code', FailureCode.unknown)));
  });
}

class _Source implements StoreDiscoveryRemoteDataSource {
  Object? error;
  StoreQuery? query;
  @override
  Future<List<CuisineModel>> getActiveCuisines() async {
    if (error != null) throw error!;
    return [CuisineModel.fromJson(cuisineJson())];
  }

  @override
  Future<StorePageModel> getStores(StoreQuery value) async {
    query = value;
    if (error != null) throw error!;
    return StorePageModel.fromJson(storeResponseJson(
        items: [storeJson()],
        number: 2,
        pages: 7,
        count: 130,
        previous: true,
        next: true));
  }
}
