import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luqma_app/features/catalog/data/repositories/category_snapshot_cache_impl.dart';
import '../support/menu_fixtures.dart';
import '../../home/support/main_category_fixtures.dart';

void main() {
  test('main and per-store snapshots survive recreation without mixing stores',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first = CategorySnapshotCacheImpl(preferences);
    await first.writeMainCategories([homeCategory()]);
    await first.writeMenuCategories(storeId, [menuCategory()]);
    final restored = CategorySnapshotCacheImpl(preferences);
    expect(restored.readMainCategories(), [homeCategory()]);
    expect(restored.readMenuCategories(storeId), [menuCategory()]);
    expect(restored.readMenuCategories('20000000-aaaa-4000-8000-000000000099'),
        isNull);
    await first.writeMenuCategories(storeId, []);
    expect(restored.readMenuCategories(storeId), isEmpty);
  });
  test('invalid cache is a miss and never becomes a fake empty result',
      () async {
    SharedPreferences.setMockInitialValues(
        {'catalog_categories_v1_main': '{broken'});
    final cache =
        CategorySnapshotCacheImpl(await SharedPreferences.getInstance());
    expect(cache.readMainCategories(), isNull);
  });
}
