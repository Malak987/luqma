import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_discovery_remote_data_source.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_discovery_repository_impl.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/repositories/store_discovery_repository.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_cuisines_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_stores_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_discovery_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/support/catalog_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await sl.reset();
  });

  Future<void> configure() async =>
      configureDependencies(preferences: await SharedPreferences.getInstance());

  test('registers guarded lazy-singleton infrastructure/use cases/paging',
      () async {
    await configure();
    expect(sl<StoreDiscoveryRemoteDataSource>(),
        isA<StoreDiscoveryRemoteDataSourceImpl>());
    expect(sl<StoreDiscoveryRepository>(), isA<StoreDiscoveryRepositoryImpl>());
    final remote = sl<StoreDiscoveryRemoteDataSource>();
    final repository = sl<StoreDiscoveryRepository>();
    final cuisines = sl<GetActiveCuisinesUseCase>();
    final stores = sl<GetStoresUseCase>();
    final paging = sl<CatalogPaging>();
    await configureDependencies();
    expect(sl<StoreDiscoveryRemoteDataSource>(), same(remote));
    expect(sl<StoreDiscoveryRepository>(), same(repository));
    expect(sl<GetActiveCuisinesUseCase>(), same(cuisines));
    expect(sl<GetStoresUseCase>(), same(stores));
    expect(sl<CatalogPaging>(), same(paging));
  });

  test('parameterized cubits are fresh and use the actual category context',
      () async {
    final fake = FakeDiscoveryRepository();
    sl.registerSingleton<StoreDiscoveryRepository>(fake);
    sl.registerSingleton<CatalogPaging>(
        const CatalogPaging(firstPage: 1, pageSize: 8));
    await configure();
    final first = sl<StoreDiscoveryCubit>(param1: categoryId);
    final second = sl<StoreDiscoveryCubit>(param1: testCatalogId(88));
    addTearDown(first.close);
    addTearDown(second.close);
    expect(first, isNot(same(second)));
    expect(fake.queries, isEmpty); // resolving does not issue requests
    await first.load();
    await second.load();
    expect(fake.queries.map((q) => q.mainCategoryId),
        [categoryId, testCatalogId(88)]);
    expect(fake.queries.every((q) => q.pageSize == 8), isTrue);
    expect(sl<StoreDiscoveryRepository>(), same(fake));
    expect(sl<CatalogPaging>().pageSize, 8);
  });

  test('respects pre-registered use cases without duplicate registrations',
      () async {
    final fake = FakeDiscoveryRepository();
    final cuisineUseCase = GetActiveCuisinesUseCase(fake);
    final storeUseCase = GetStoresUseCase(fake);
    sl.registerSingleton<GetActiveCuisinesUseCase>(cuisineUseCase);
    sl.registerSingleton<GetStoresUseCase>(storeUseCase);
    await configure();
    await configureDependencies();
    final cubit = sl<StoreDiscoveryCubit>(param1: categoryId);
    addTearDown(cubit.close);
    await cubit.load();
    expect(fake.cuisineCalls, 1);
    expect(fake.queries.single.mainCategoryId, categoryId);
    expect(sl<GetActiveCuisinesUseCase>(), same(cuisineUseCase));
    expect(sl<GetStoresUseCase>(), same(storeUseCase));
  });
}
