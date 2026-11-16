import '../../../../core/error/failures.dart';
import '../entities/cart_line.dart';
import '../entities/cart_mutation.dart';
import '../repositories/cart_repository.dart';

class UpdateToCartUseCase {
  const UpdateToCartUseCase(this._repository);

  final CartRepository _repository;

  Future<CartLine> call(CartMutation mutation) {
    if (mutation.menuItemId.trim().isEmpty ||
        mutation.quantity <= 0 ||
        mutation.addonIds.any((id) => id.trim().isEmpty)) {
      throw const FailureException(
        Failure(FailureCode.validation, debugMessage: 'Invalid cart mutation'),
      );
    }
    return _repository.updateToCart(mutation);
  }
}
