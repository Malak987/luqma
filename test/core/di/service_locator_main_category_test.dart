import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/features/home/data/datasources/main_category_remote_data_source.dart';
import 'package:luqma_app/features/home/data/repositories/main_category_repository_impl.dart';
import 'package:luqma_app/features/home/domain/repositories/main_category_repository.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/support/main_category_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await configureDependencies(
        preferences: await SharedPreferences.getInstance());
  });

  tearDown(() async {
    await sl.reset();
  });

  test('registers the source, repository and use case as lazy singletons', () {
    expect(sl<MainCategoryRemoteDataSource>(),
        isA<MainCategoryRemoteDataSourceImpl>());
    expect(sl<MainCategoryRepository>(), isA<MainCategoryRepositoryImpl>());
    expect(
        sl<GetAllMainCategoriesUseCase>(), isA<GetAllMainCategoriesUseCase>());
    expect(sl<MainCategoryRemoteDataSource>(),
        same(sl<MainCategoryRemoteDataSource>()));
    expect(sl<MainCategoryRepository>(), same(sl<MainCategoryRepository>()));
    expect(sl<GetAllMainCategoriesUseCase>(),
        same(sl<GetAllMainCategoriesUseCase>()));
  });

  test('keeps HomeCubit factory-scoped with its new use case dependency',
      () async {
    final first = sl<HomeCubit>();
    final second = sl<HomeCubit>();
    addTearDown(first.close);
    addTearDown(second.close);

    expect(first, isNot(same(second)));
  });

  test('configuration remains idempotent', () async {
    final repository = sl<MainCategoryRepository>();
    final useCase = sl<GetAllMainCategoriesUseCase>();

    await configureDependencies();

    expect(sl<MainCategoryRepository>(), same(repository));
    expect(sl<GetAllMainCategoriesUseCase>(), same(useCase));
  });

  test('honors a pre-registered repository without making a network request',
      () async {
    await sl.reset();
    final fake = FakeMainCategoryRepository();
    sl.registerSingleton<MainCategoryRepository>(fake);
    await configureDependencies(
        preferences: await SharedPreferences.getInstance());

    expect(sl<MainCategoryRepository>(), same(fake));
    expect(await sl<GetAllMainCategoriesUseCase>()(), isEmpty);
    expect(fake.calls, 1);
  });
}
