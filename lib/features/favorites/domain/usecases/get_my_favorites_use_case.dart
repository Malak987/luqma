import '../../../../core/error/failures.dart';
import '../entities/favorites_page.dart';
import '../repositories/favorites_repository.dart';

class GetMyFavoritesUseCase {
  const GetMyFavoritesUseCase(this._repository);
  final FavoritesRepository _repository;

  Future<FavoritesPage> call({
    required int pageNumber,
    required int pageSize,
  }) {
    if (pageNumber < 0 || pageSize <= 0) {
      throw const FailureException(
        Failure(FailureCode.validation, debugMessage: 'Invalid favorite page'),
      );
    }
    return _repository.getMyFavorites(
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }
}
