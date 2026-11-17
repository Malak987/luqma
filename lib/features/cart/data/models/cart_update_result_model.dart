import '../../domain/entities/cart_update_result.dart';
import 'cart_json.dart';

/// The minimal confirmed UpdateToCart response payload.
///
/// A mutation response is not a CartLine snapshot: the API only guarantees
/// [isRemoved]. The Cart Cubit refreshes GetMyCart and GetCount after every
/// successful mutation to obtain the authoritative lines and badge quantity.
class CartUpdateResultModel {
  const CartUpdateResultModel({required this.isRemoved});

  final bool isRemoved;

  factory CartUpdateResultModel.fromJson(Object? value) {
    final json = cartObject(value, 'UpdateToCart result');
    return CartUpdateResultModel(
      isRemoved: cartRequiredBool(json, 'isRemoved'),
    );
  }

  CartUpdateResult toDomain() => CartUpdateResult(isRemoved: isRemoved);
}
