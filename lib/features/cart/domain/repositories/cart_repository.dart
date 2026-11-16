import '../entities/cart.dart';
import '../entities/cart_count.dart';
import '../entities/cart_line.dart';
import '../entities/cart_mutation.dart';

abstract interface class CartRepository {
  Future<CartLine> addToCart(CartMutation mutation);
  Future<CartLine> updateToCart(CartMutation mutation);
  Future<Cart> getMyCart();
  Future<CartCount> getCount();
}
