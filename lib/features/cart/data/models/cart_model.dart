import '../../domain/entities/cart.dart';
import 'cart_json.dart';
import 'cart_line_model.dart';

/// GetMyCart.data. Its confirmed outer fields are items, totalQuantity and
/// subTotal; item records use the verified cart-line DTO.
class CartModel {
  CartModel({
    required List<CartLineModel> items,
    required this.totalQuantity,
    required this.subTotal,
  }) : items = List<CartLineModel>.unmodifiable(items);

  final List<CartLineModel> items;
  final int totalQuantity;
  final num subTotal;

  factory CartModel.fromJson(Object? value) {
    final json = cartObject(value, 'GetMyCart data');
    final subTotal = cartRequiredNumber(json, 'subTotal');
    if (subTotal < 0) {
      throw const FormatException('GetMyCart subTotal cannot be negative');
    }
    return CartModel(
      items: cartRequiredList(
        json,
        'items',
      ).map(CartLineModel.fromJson).toList(growable: false),
      totalQuantity: cartRequiredNonNegativeInt(json, 'totalQuantity'),
      subTotal: subTotal,
    );
  }

  Cart toDomain() => Cart(
    items: items.map((item) => item.toDomain()).toList(growable: false),
    totalQuantity: totalQuantity,
    subTotal: subTotal,
  );
}
