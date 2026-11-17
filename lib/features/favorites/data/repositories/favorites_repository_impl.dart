import '../../../../core/error/failures.dart';
import '../../domain/entities/favorite_menu_item.dart';
import '../../domain/entities/favorites_page.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._remoteDataSource);

  final FavoritesRemoteDataSource _remoteDataSource;

  @override
  Future<FavoriteMenuItem> addToFavorites(String menuItemId) => _mapFailure(
        () async =>
            (await _remoteDataSource.addToFavorites(menuItemId)).toDomain(),
      );

  @override
  Future<void> removeFromFavorites(String menuItemId) =>
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
