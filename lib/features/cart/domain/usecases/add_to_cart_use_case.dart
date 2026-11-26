import '../../../../core/error/failures.dart';
import '../entities/cart_line.dart';
import '../entities/cart_mutation.dart';
import '../repositories/cart_repository.dart';

class AddToCartUseCase {
  const AddToCartUseCase(this._repository);

  final CartRepository _repository;

  Future<CartLine> call(CartMutation mutation) {
    _validate(mutation);
    return _repository.addToCart(mutation);
  }
}

void _validate(CartMutation mutation) {
  if (mutation.menuItemId.trim().isEmpty ||
      mutation.quantity < 1 ||
      mutation.quantity > kMaxCartLineQuantity ||
      mutation.addonIds.any((id) => id.trim().isEmpty)) {
    throw const FailureException(
      Failure(FailureCode.validation, debugMessage: 'Invalid cart mutation'),
    );
  }
}
