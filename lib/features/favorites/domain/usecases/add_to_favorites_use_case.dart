import '../../../../core/error/failures.dart';
import '../entities/favorite_menu_item.dart';
import '../queries/favorite_identifiers.dart';
import '../repositories/favorites_repository.dart';

class AddToFavoritesUseCase {
  const AddToFavoritesUseCase(this._repository);
  final FavoritesRepository _repository;

  Future<FavoriteMenuItem> call(String menuItemId) {
    final id = menuItemId.trim();
    if (!isFavoriteMenuItemId(id)) {
      throw const FailureException(
        Failure(FailureCode.validation, debugMessage: 'Invalid favorite item'),
      );
    }
    return _repository.addToFavorites(id);
  }
}
