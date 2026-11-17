import 'dart:convert';

import '../../../../core/error/failures.dart';
import '../../../../core/storage/preferences_storage_service.dart';
import '../../domain/entities/favorite_menu_item.dart';
import '../../domain/entities/favorites_cache_snapshot.dart';
import '../../domain/queries/favorite_identifiers.dart';
import '../../domain/entities/favorites_page.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_data_source.dart';
import '../models/favorite_menu_item_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._remoteDataSource, this._preferences);

  final FavoritesRemoteDataSource _remoteDataSource;
  final PreferencesStorageService _preferences;

  static const int _maxCachedIds = 5000;

  String _cacheKey(String userId) =>
      'favorites_cache_v1_${base64Url.encode(utf8.encode(userId))}';

  @override
  Future<FavoritesCacheSnapshot?> readCache(String userId) async {
    final encoded = _preferences.getString(_cacheKey(userId));
    if (encoded == null) return null;
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, dynamic> || value['version'] != 1) {
        throw const FormatException('Unsupported cache version');
      }
      final rawIds = value['favoriteIds'];
      final rawItems = value['items'];
      if (rawIds is! List ||
          rawItems is! List ||
          rawIds.length > _maxCachedIds ||
          rawItems.length > 20) {
        throw const FormatException('Invalid cached favorites payload structure');
      }
      final ids = rawIds
          .whereType<String>()
          .map((id) => id.toLowerCase())
          .toList(growable: false);
      if (ids.length != rawIds.length ||
          ids.any((id) => !isFavoriteMenuItemId(id)) ||
          ids.toSet().length != ids.length) {
        throw const FormatException('Invalid cached favorite identifiers');
      }
      final items = rawItems
          .map((item) => FavoriteMenuItemModel.fromJson(item).toDomain())
          .toList(growable: false);
      final totalCount = _cacheInt(value, 'totalCount');
      final complete = value['indexComplete'] == true &&
          ids.length <= _maxCachedIds &&
          ids.length == totalCount;
      if (items.any((item) => !ids.contains(item.menuItemId.toLowerCase()))) {
        throw const FormatException('Cached item is missing from favorite index');
      }
      return FavoritesCacheSnapshot(
        favoriteIds: ids,
        items: items,
        totalCount: totalCount,
        pageNumber: _cacheInt(value, 'pageNumber'),
        totalPages: _cacheInt(value, 'totalPages'),
        hasNextPage: value['hasNextPage'] == true,
        hasPreviousPage: value['hasPreviousPage'] == true,
        indexComplete: complete,
        savedAt: DateTime.parse(value['savedAt'] as String),
      );
    } catch (_) {
      await _preferences.remove(_cacheKey(userId));
      return null;
    }
  }

  @override
  Future<void> writeCache(
    String userId,
    FavoritesCacheSnapshot snapshot,
  ) async {
    final ids = snapshot.favoriteIds.take(_maxCachedIds).toList(growable: false);
    final complete = snapshot.indexComplete &&
        snapshot.favoriteIds.length <= _maxCachedIds;
    final saved = await _preferences.setString(
      _cacheKey(userId),
      jsonEncode(<String, Object?>{
        'version': 1,
        'favoriteIds': ids,
        'items': snapshot.items.take(20).map(_itemJson).toList(growable: false),
        'totalCount': snapshot.totalCount,
        'pageNumber': snapshot.pageNumber,
        'totalPages': snapshot.totalPages,
        'hasNextPage': snapshot.hasNextPage,
        'hasPreviousPage': snapshot.hasPreviousPage,
        'indexComplete': complete,
        'savedAt': snapshot.savedAt.toUtc().toIso8601String(),
      }),
    );
    if (!saved) throw StateError('Favorites cache could not be persisted');
  }

  static int _cacheInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int || value < 0) throw FormatException('Invalid $key');
    return value;
  }

  static Map<String, Object?> _itemJson(FavoriteMenuItem item) =>
      <String, Object?>{
        'id': item.id,
        'menuItemId': item.menuItemId,
        'nameAr': item.nameAr,
        'nameEn': item.nameEn,
        'descriptionAr': item.descriptionAr,
        'descriptionEn': item.descriptionEn,
        'imageUrl': item.imageUrl,
        'price': item.price,
        'compareAtPrice': item.compareAtPrice,
        'isAvailable': item.isAvailable,
        'addedAt': item.addedAt,
      };

  @override
  Future<FavoriteMenuItem> addToFavorites(String menuItemId) => _mapFailure(
        () async =>
            (await _remoteDataSource.addToFavorites(menuItemId)).toDomain(),
      );

  @override
  Future<String> removeFromFavorites(String menuItemId) =>
      _mapFailure(() => _remoteDataSource.removeFromFavorites(menuItemId));

  @override
  Future<FavoritesPage> getMyFavorites({
    required int pageNumber,
    required int pageSize,
  }) =>
      _mapFailure(() async {
        final page = await _remoteDataSource.getMyFavorites(
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        return FavoritesPage(
          items: page.items.map((item) => item.toDomain()).toList(
                growable: false,
              ),
          pageNumber: page.pageNumber,
          totalPages: page.totalPages,
          totalCount: page.totalCount,
          hasPreviousPage: page.hasPreviousPage,
          hasNextPage: page.hasNextPage,
        );
      });

  @override
  Future<bool> isFavorite(String menuItemId) =>
      _mapFailure(() => _remoteDataSource.isFavorite(menuItemId));

  @override
  Future<int> getCount() => _mapFailure(_remoteDataSource.getCount);

  Future<T> _mapFailure<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RemoteException catch (error) {
      throw FailureException(Failure(error.code, debugMessage: error.message));
    } on FailureException {
      rethrow;
    } catch (_) {
      throw const FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: 'Favorite operation could not be completed',
        ),
      );
    }
  }
}
