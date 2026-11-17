import '../entities/favorite_menu_item.dart';
import '../entities/favorites_page.dart';

abstract interface class FavoritesRepository {
  Future<FavoriteMenuItem> addToFavorites(String menuItemId);
  Future<void> removeFromFavorites(String menuItemId);
  Future<FavoritesPage> getMyFavorites({
    required int pageNumber,
    required int pageSize,
  });
  Future<bool> isFavorite(String menuItemId);
  Future<int> getCount();
}
