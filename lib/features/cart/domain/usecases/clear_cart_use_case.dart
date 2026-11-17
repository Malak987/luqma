import '../repositories/cart_repository.dart';

/// Deletes the authenticated customer's complete cart through the confirmed
/// Clear endpoint. Snapshot synchronization belongs to the presentation
/// coordinator, because this endpoint has no confirmed response body.
class ClearCartUseCase {
  const ClearCartUseCase(this._repository);

  final CartRepository _repository;

  Future<void> call() => _repository.clearCart();
}
