import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:luqma_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:luqma_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorites_cache_snapshot.dart';
import 'package:luqma_app/features/favorites/domain/usecases/add_to_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/get_favorites_count_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/get_my_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/is_favorite_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/remove_from_favorites_use_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await configureDependencies(preferences: await SharedPreferences.getInstance());
  });

  tearDown(() => sl.reset());

  test('registers the Favorites API data, domain and action dependencies', () {
    expect(sl<FavoritesRemoteDataSource>(), isA<FavoritesRemoteDataSourceImpl>());
    expect(sl<FavoritesRepository>(), isA<FavoritesRepositoryImpl>());
    expect(sl<AddToFavoritesUseCase>(), isA<AddToFavoritesUseCase>());
    expect(sl<RemoveFromFavoritesUseCase>(), isA<RemoveFromFavoritesUseCase>());
    expect(sl<GetMyFavoritesUseCase>(), isA<GetMyFavoritesUseCase>());
    expect(sl<IsFavoriteUseCase>(), isA<IsFavoriteUseCase>());
    expect(sl<GetFavoritesCountUseCase>(), isA<GetFavoritesCountUseCase>());
  });

  test('persists cache snapshots under an authenticated user scoped key', () async {
    final repository = sl<FavoritesRepository>();
    final snapshot = FavoritesCacheSnapshot(
      favoriteIds: const <String>[],
      items: const [],
      totalCount: 0,
      pageNumber: 1,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
      indexComplete: true,
      savedAt: DateTime.now().toUtc(),
    );

    await repository.writeCache('account-a', snapshot);

    expect((await repository.readCache('account-a'))?.indexComplete, isTrue);
    expect(await repository.readCache('account-b'), isNull);
  });
}
