import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../home/data/models/main_category_model.dart';
import '../../../home/domain/entities/home_category.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/queries/catalog_identifiers.dart';
import '../../domain/repositories/category_snapshot_cache.dart';
import '../models/menu_category_model.dart';

/// Public category snapshots only; never stores cart, favorites or credentials.
class CategorySnapshotCacheImpl implements CategorySnapshotCache {
  CategorySnapshotCacheImpl(this._preferences);
  final SharedPreferences _preferences;
  static const _mainKey = 'catalog_categories_v1_main';
  static const _menuPrefix = 'catalog_categories_v1_menu_';

  List<T>? _read<T>(String key, T Function(Object?) parse) {
    try {
      final raw = _preferences.getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return List<T>.unmodifiable(decoded.map(parse));
    } catch (_) {
      return null; // A damaged cache is a miss, not an empty server result.
    }
  }

  @override
  List<HomeCategory>? readMainCategories() =>
      _read(_mainKey, (value) => MainCategoryModel.fromJson(value).toDomain());

  @override
  Future<void> writeMainCategories(List<HomeCategory> categories) async {
    final values = categories
        .map((x) => <String, Object?>{
              'id': x.id,
              'nameAr': x.nameAr,
              'nameEn': x.nameEn,
              'iconUrl': x.iconUrl,
              'displayOrder': x.displayOrder,
              'isActive': x.isActive,
            })
        .toList();
    await _preferences.setString(_mainKey, jsonEncode(values));
  }

  @override
  List<MenuCategory>? readMenuCategories(String storeId) {
    if (!isCatalogId(storeId)) return null;
    final items = _read('$_menuPrefix${storeId.toLowerCase()}',
        (value) => MenuCategoryModel.fromJson(value).toDomain());
    if (items == null ||
        items.any((x) => x.storeId.toLowerCase() != storeId.toLowerCase()))
      return null;
    return items;
  }

  @override
  Future<void> writeMenuCategories(
      String storeId, List<MenuCategory> categories) async {
    if (!isCatalogId(storeId) ||
        categories.any((x) => x.storeId.toLowerCase() != storeId.toLowerCase()))
      return;
    final values = categories
        .map((x) => <String, Object?>{
              'id': x.id,
              'storeId': x.storeId,
              'nameAr': x.nameAr,
              'nameEn': x.nameEn,
              'imageUrl': x.imageUrl,
              'displayOrder': x.displayOrder,
              'isActive': x.isActive,
              'itemsCount': x.itemsCount,
            })
        .toList();
    await _preferences.setString(
        '$_menuPrefix${storeId.toLowerCase()}', jsonEncode(values));
  }
}
