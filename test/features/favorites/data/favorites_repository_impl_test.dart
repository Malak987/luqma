import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:luqma_app/features/favorites/data/models/favorite_menu_item_model.dart';
import 'package:luqma_app/features/favorites/data/models/favorite_page_model.dart';
import 'package:luqma_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorite_menu_item.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorites_cache_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/favorite_fixtures.dart';

class _FakeFavoritesRemoteDataSource implements FavoritesRemoteDataSource {
  @override
  Future<FavoriteMenuItemModel> addToFavorites(String menuItemId) async =>
      FavoriteMenuItemModel.fromJson(favoriteItemJson(menuItemId: menuItemId));

  @override
  Future<String> removeFromFavorites(String menuItemId) async => menuItemId;

  @override
  Future<FavoritePageModel> getMyFavorites({
    required int pageNumber,
    required int pageSize,
  }) async =>
      FavoritePageModel.fromJson(
        favoriteEnvelope(
          data: favoritePageJson(
            items: <Object?>[favoriteItemJson()],
            totalCount: 1,
          ),
        ),
      );

  @override
  Future<bool> isFavorite(String menuItemId) async => true;

  @override
  Future<int> getCount() async => 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PreferencesStorageService preferencesService;
  late FavoritesRepositoryImpl repository;
  const userId = 'user-123';
  final cacheKey =
      'favorites_cache_v1_${base64Url.encode(utf8.encode(userId))}';

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    preferencesService = PreferencesStorageService(prefs);
    repository = FavoritesRepositoryImpl(
      _FakeFavoritesRemoteDataSource(),
      preferencesService,
    );
  });

  test('readCache returns null and clears invalid JSON or bad version',
      () async {
    await preferencesService.setString(cacheKey, 'invalid-json');
    expect(await repository.readCache(userId), isNull);
    expect(preferencesService.getString(cacheKey), isNull);

    await preferencesService.setString(
      cacheKey,
      jsonEncode(<String, Object?>{'version': 2}),
    );
    expect(await repository.readCache(userId), isNull);
    expect(preferencesService.getString(cacheKey), isNull);
  });

  test('readCache clears corrupted ID lists, duplicates, or missing item IDs',
      () async {
    await preferencesService.setString(
      cacheKey,
      jsonEncode(<String, Object?>{
        'version': 1,
        'favoriteIds': <String>['not-a-uuid'],
        'items': <Object?>[favoriteItemJson()],
        'totalCount': 1,
        'pageNumber': 1,
        'totalPages': 1,
        'hasNextPage': false,
        'hasPreviousPage': false,
        'indexComplete': true,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    expect(await repository.readCache(userId), isNull);
    expect(preferencesService.getString(cacheKey), isNull);

    await preferencesService.setString(
      cacheKey,
      jsonEncode(<String, Object?>{
        'version': 1,
        'favoriteIds': <String>[favoriteMenuItemId, favoriteMenuItemId],
        'items': <Object?>[favoriteItemJson()],
        'totalCount': 2,
        'pageNumber': 1,
        'totalPages': 1,
        'hasNextPage': false,
        'hasPreviousPage': false,
        'indexComplete': true,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    expect(await repository.readCache(userId), isNull);
    expect(preferencesService.getString(cacheKey), isNull);

    await preferencesService.setString(
      cacheKey,
      jsonEncode(<String, Object?>{
        'version': 1,
        'favoriteIds': <String>[otherFavoriteMenuItemId],
        'items': <Object?>[favoriteItemJson()],
        'totalCount': 1,
        'pageNumber': 1,
        'totalPages': 1,
        'hasNextPage': false,
        'hasPreviousPage': false,
        'indexComplete': true,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    expect(await repository.readCache(userId), isNull);
    expect(preferencesService.getString(cacheKey), isNull);
  });

  test('writeCache persists valid snapshot and truncates IDs exceeding 5,000',
      () async {
    final now = DateTime.now().toUtc();
    final item = favoriteItem();
    final largeIds = <String>[
      item.menuItemId,
      ...List<String>.generate(
        5000,
        (index) =>
            '40000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
      ),
    ];

    final snapshot = FavoritesCacheSnapshot(
      favoriteIds: largeIds,
      items: <FavoriteMenuItem>[item],
      totalCount: 5001,
      pageNumber: 1,
      totalPages: 251,
      hasNextPage: true,
      hasPreviousPage: false,
      indexComplete: false,
      savedAt: now,
    );

    await repository.writeCache(userId, snapshot);
    final storedRaw = preferencesService.getString(cacheKey);
    expect(storedRaw, isNotNull);

    final decoded = jsonDecode(storedRaw!) as Map<String, dynamic>;
    final storedIds = (decoded['favoriteIds'] as List).cast<String>();
    expect(storedIds.length, 5000);
    expect(decoded['indexComplete'], isFalse);

    final restored = await repository.readCache(userId);
    expect(restored, isNotNull);
    expect(restored!.favoriteIds.length, 5000);
    expect(restored.indexComplete, isFalse);
    expect(restored.totalCount, 5001);
  });
}
