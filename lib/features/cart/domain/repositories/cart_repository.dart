import '../entities/cart.dart';
import '../entities/cart_count.dart';
import '../entities/cart_line.dart';
import '../entities/cart_mutation.dart';
import '../entities/cart_update_result.dart';

abstract interface class CartRepository {
  Future<CartLine> addToCart(CartMutation mutation);
  Future<CartUpdateResult> updateToCart(CartMutation mutation);
  Future<void> clearCart();
  Future<Cart> getMyCart();
  Future<CartCount> getCount();
}
