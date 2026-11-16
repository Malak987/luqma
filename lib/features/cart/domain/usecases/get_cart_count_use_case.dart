import '../entities/cart_count.dart';
import '../repositories/cart_repository.dart';

class GetCartCountUseCase {
  const GetCartCountUseCase(this._repository);

  final CartRepository _repository;

  Future<CartCount> call() => _repository.getCount();
}
