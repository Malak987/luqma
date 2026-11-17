import '../../../../core/error/failures.dart';
import '../queries/favorite_identifiers.dart';
import '../repositories/favorites_repository.dart';

class IsFavoriteUseCase {
  const IsFavoriteUseCase(this._repository);
  final FavoritesRepository _repository;

  Future<bool> call(String menuItemId) {
    final id = menuItemId.trim();
    if (!isFavoriteMenuItemId(id)) {
      throw const FailureException(
        Failure(FailureCode.validation, debugMessage: 'Invalid favorite item'),
      );
    }
    return _repository.isFavorite(id);
  }
}
