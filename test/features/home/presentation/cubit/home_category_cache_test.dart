import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/catalog/data/repositories/category_snapshot_cache_impl.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_state.dart';
import '../../support/main_category_fixtures.dart';
import '../../support/store_fixtures.dart';

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());
  @override
  Future<String?> getUserName() async => 'User';
}

void main() {
  test(
      'cached categories survive failed refresh and remain marked with failure',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cache =
        CategorySnapshotCacheImpl(await SharedPreferences.getInstance());
    await cache.writeMainCategories([homeCategory()]);
    final repo = FakeMainCategoryRepository(exception: Exception('offline'));
    final stores = HomeStoreDependencies();
    final cubit = HomeCubit(
        secureStorageService: _Storage(),
        getAllMainCategoriesUseCase: GetAllMainCategoriesUseCase(repo),
        getStoresUseCase: stores.useCase,
        catalogPaging: stores.paging,
        categoryCache: cache);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.categories, [homeCategory()]);
    expect(cubit.state.categoriesStatus, HomeCategoriesStatus.success);
    expect(cubit.state.categoriesFailure, isNotNull);
    expect(cache.readMainCategories(), [homeCategory()]);
    repo.exception = null;
    repo.categories = [homeCategory(nameEn: 'Updated')];
    await cubit.retryCategories();
    expect(cubit.state.categories.single.nameEn, 'Updated');
    expect(cubit.state.categoriesFailure, isNull);
    expect(cache.readMainCategories()!.single.nameEn, 'Updated');
  });
}
