import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_menu_remote_data_source.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_menu_repository_impl.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/repositories/store_menu_repository.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/support/menu_fixtures.dart';

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

  test(
      'menu infrastructure/use cases are lazy singletons guarded across repeated composition',
      () async {
    await configure();
    final source = sl<StoreMenuRemoteDataSource>();
    final repository = sl<StoreMenuRepository>();
    final categories = sl<GetActiveMenuCategoriesUseCase>();
    final products = sl<GetMenuItemsUseCase>();
    expect(source, isA<StoreMenuRemoteDataSourceImpl>());
    expect(repository, isA<StoreMenuRepositoryImpl>());
    await configureDependencies();
    expect(sl<StoreMenuRemoteDataSource>(), same(source));
    expect(sl<StoreMenuRepository>(), same(repository));
    expect(sl<GetActiveMenuCategoriesUseCase>(), same(categories));
    expect(sl<GetMenuItemsUseCase>(), same(products));
  });

  test(
      'factory receives actual store context, respects overrides and never loads on resolution',
      () async {
    final fake = FakeMenuRepository();
    fake.onCategories = (id) async => [menuCategory(store: id)];
    sl.registerSingleton<StoreMenuRepository>(fake);
    sl.registerSingleton<CatalogPaging>(
        const CatalogPaging(firstPage: 0, pageSize: 7));
    await configure();
    final first = sl<StoreMenuCubit>(param1: storeId);
    final second = sl<StoreMenuCubit>(param1: otherStoreId);
    addTearDown(first.close);
    addTearDown(second.close);
    expect(first, isNot(same(second)));
    expect(fake.categoryStores, isEmpty);
    expect(fake.queries, isEmpty);
    await first.load();
    await second.load();
    expect(fake.categoryStores, [storeId, otherStoreId]);
    expect(fake.queries.map((q) => q.storeId), [storeId, otherStoreId]);
    expect(fake.queries.every((q) => q.pageSize == 7 && q.pageNumber == 0),
        isTrue);
    expect(sl<StoreMenuRepository>(), same(fake));
  });

  test('guarded registrations honor injected menu use cases', () async {
    final fake = FakeMenuRepository();
    final categories = GetActiveMenuCategoriesUseCase(fake);
    final products = GetMenuItemsUseCase(fake);
    sl.registerSingleton<GetActiveMenuCategoriesUseCase>(categories);
    sl.registerSingleton<GetMenuItemsUseCase>(products);
    await configure();
    await configureDependencies();
    final cubit = sl<StoreMenuCubit>(param1: storeId);
    addTearDown(cubit.close);
    await cubit.load();
    expect(fake.categoryStores, [storeId]);
    expect(fake.queries.single.storeId, storeId);
    expect(sl<GetActiveMenuCategoriesUseCase>(), same(categories));
    expect(sl<GetMenuItemsUseCase>(), same(products));
  });
}
