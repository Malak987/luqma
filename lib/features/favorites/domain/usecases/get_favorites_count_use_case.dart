import '../repositories/favorites_repository.dart';

class GetFavoritesCountUseCase {
  const GetFavoritesCountUseCase(this._repository);
  final FavoritesRepository _repository;

  Future<int> call() => _repository.getCount();
}
