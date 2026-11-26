import '../../../../core/error/failures.dart';
import '../entities/cart_mutation.dart';
import '../entities/cart_update_result.dart';
import '../repositories/cart_repository.dart';

class UpdateToCartUseCase {
  const UpdateToCartUseCase(this._repository);

  final CartRepository _repository;

  Future<CartUpdateResult> call(CartMutation mutation) {
    // The backend-confirmed UpdateToCart contract interprets zero as removal
    // of this exact menu item / option / add-on configuration.
    if (mutation.menuItemId.trim().isEmpty ||
        mutation.quantity < 0 ||
        mutation.quantity > kMaxCartLineQuantity ||
        mutation.addonIds.any((id) => id.trim().isEmpty)) {
      throw const FailureException(
        Failure(FailureCode.validation, debugMessage: 'Invalid cart mutation'),
      );
    }
    return _repository.updateToCart(mutation);
  }
}
