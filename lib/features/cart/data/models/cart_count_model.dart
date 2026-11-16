import '../../domain/entities/cart_count.dart';
import 'cart_json.dart';

/// GetCount.data.
class CartCountModel {
  const CartCountModel({required this.linesCount, required this.totalQuantity});

  final int linesCount;
  final int totalQuantity;

  factory CartCountModel.fromJson(Object? value) {
    final json = cartObject(value, 'GetCount data');
    return CartCountModel(
      linesCount: cartRequiredNonNegativeInt(json, 'linesCount'),
      totalQuantity: cartRequiredNonNegativeInt(json, 'totalQuantity'),
    );
  }

  CartCount toDomain() =>
      CartCount(linesCount: linesCount, totalQuantity: totalQuantity);
}
