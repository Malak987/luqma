import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class GetMyCartUseCase {
  const GetMyCartUseCase(this._repository);

  final CartRepository _repository;

  Future<Cart> call() => _repository.getMyCart();
}
