import '../entities/favorite_menu_item.dart';
import '../entities/favorites_cache_snapshot.dart';
import '../entities/favorites_page.dart';

abstract interface class FavoritesRepository {
  Future<FavoritesCacheSnapshot?> readCache(String userId);
  Future<void> writeCache(String userId, FavoritesCacheSnapshot snapshot);
  Future<FavoriteMenuItem> addToFavorites(String menuItemId);
  Future<String> removeFromFavorites(String menuItemId);
  Future<FavoritesPage> getMyFavorites({
    required int pageNumber,
    required int pageSize,
  });
  Future<bool> isFavorite(String menuItemId);
  Future<int> getCount();
}
