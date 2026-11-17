import 'package:luqma_app/features/cart/domain/entities/cart.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_count.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_line.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_mutation.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_update_result.dart';
import 'package:luqma_app/features/cart/domain/repositories/cart_repository.dart';

const cartLineId = '30000000-aaaa-4000-8000-000000000001';
const cartMenuItemId = '30000000-bbbb-4000-8000-000000000002';
const cartOptionId = '30000000-cccc-4000-8000-000000000003';
const cartAddonId = '30000000-dddd-4000-8000-000000000004';
const otherCartLineId = '30000000-eeee-4000-8000-000000000005';
const otherCartOptionId = '30000000-ffff-4000-8000-000000000006';
const otherCartAddonId = '30000000-1111-4000-8000-000000000007';

Map<String, Object?> cartEnvelope({
  required Object? data,
  bool succeeded = true,
  String message = 'ok',
}) =>
    <String, Object?>{
      'message': message,
      'data': data,
      'isSucceeded': succeeded,
      'timestamp': '2026-11-16T17:51:17.0237074Z',
    };

Map<String, Object?> cartLineJson({
  String id = cartLineId,
  String menuItemId = cartMenuItemId,
  Object? menuItemOptionId = cartOptionId,
  Object? optionNameAr = 'دبل',
  Object? optionNameEn = 'Double',
  Object? optionPrice = 70,
  List<Object?> addons = const <Object?>[],
  int quantity = 2,
  bool removed = false,
  bool available = true,
}) =>
    <String, Object?>{
      'id': id,
      'menuItemId': menuItemId,
      'nameAr': 'وجبة فراخ مشوية',
      'nameEn': 'Grilled Chicken Meal',
      'imageUrl': 'https://images.example.test/chicken.jpg',
      'menuItemOptionId': menuItemOptionId,
      'optionNameAr': optionNameAr,
      'optionNameEn': optionNameEn,
      'optionPrice': optionPrice,
      'addons': addons,
      'unitPrice': 270,
      'quantity': quantity,
      'lineTotal': 270 * quantity,
      'isRemoved': removed,
      'isAvailable': available,
    };

Map<String, Object?> cartAddonJson() => <String, Object?>{
      'id': cartAddonId,
      'nameAr': 'إضافة أرز',
      'nameEn': 'Extra Rice',
      'price': 20,
    };

Map<String, Object?> cartJson({
  List<Object?> items = const <Object?>[],
  int totalQuantity = 0,
  num subTotal = 0,
}) =>
    <String, Object?>{
      'items': items,
      'totalQuantity': totalQuantity,
      'subTotal': subTotal,
    };

Map<String, Object?> cartCountJson({
  int linesCount = 0,
  int totalQuantity = 0,
}) =>
    <String, Object?>{
      'linesCount': linesCount,
      'totalQuantity': totalQuantity,
    };

CartLine cartLine({
  String id = cartLineId,
  String menuItemId = cartMenuItemId,
  String? menuItemOptionId = cartOptionId,
  String? optionNameAr,
  String? optionNameEn,
  num? optionPrice,
  int quantity = 2,
  bool removed = false,
  bool available = true,
  List<CartLineAddon> addons = const <CartLineAddon>[],
}) =>
    CartLine(
      id: id,
      menuItemId: menuItemId,
      nameAr: 'وجبة فراخ مشوية',
      nameEn: 'Grilled Chicken Meal',
      imageUrl: 'https://images.example.test/chicken.jpg',
      menuItemOptionId: menuItemOptionId,
      optionNameAr: optionNameAr ?? (menuItemOptionId == null ? null : 'دبل'),
      optionNameEn: optionNameEn ?? (menuItemOptionId == null ? null : 'Double'),
      optionPrice: optionPrice ?? (menuItemOptionId == null ? null : 70),
      addons: addons,
      unitPrice: 270,
      quantity: quantity,
      lineTotal: 270 * quantity,
      isRemoved: removed,
      isAvailable: available,
    );

Cart cart({List<CartLine> items = const <CartLine>[]}) => Cart(
      items: items,
      totalQuantity: items.fold(0, (sum, line) => sum + line.quantity),
      subTotal: items.fold<num>(0, (sum, line) => sum + line.lineTotal),
    );

CartCount cartCount({int linesCount = 0, int totalQuantity = 0}) =>
    CartCount(linesCount: linesCount, totalQuantity: totalQuantity);

class FakeCartRepository implements CartRepository {
  Cart currentCart = cart();
  CartCount currentCount = cartCount();
  CartLine currentLine = cartLine();
  CartUpdateResult currentUpdateResult = const CartUpdateResult(isRemoved: false);
  Object? error;
  CartMutation? lastAdd;
  CartMutation? lastUpdate;
  int clearCalls = 0;
  int getMyCartCalls = 0;
  int getCountCalls = 0;
  Future<void> Function()? onClear;
  Future<CartLine> Function(CartMutation mutation)? onAdd;
  Future<CartUpdateResult> Function(CartMutation mutation)? onUpdate;
  Future<Cart> Function()? onGetMyCart;
  Future<CartCount> Function()? onGetCount;

  @override
  Future<CartLine> addToCart(CartMutation mutation) async {
    if (error != null) throw error!;
    lastAdd = mutation;
    return onAdd == null ? currentLine : await onAdd!(mutation);
  }

  @override
  Future<CartUpdateResult> updateToCart(CartMutation mutation) async {
    if (error != null) throw error!;
    lastUpdate = mutation;
    return onUpdate == null
        ? currentUpdateResult
        : await onUpdate!(mutation);
  }

  @override
  Future<void> clearCart() async {
    if (error != null) throw error!;
    clearCalls++;
    if (onClear != null) await onClear!();
  }

  @override
  Future<Cart> getMyCart() async {
    getMyCartCalls++;
    if (error != null) throw error!;
    return onGetMyCart == null ? currentCart : await onGetMyCart!();
  }

  @override
  Future<CartCount> getCount() async {
    getCountCalls++;
    if (error != null) throw error!;
    return onGetCount == null ? currentCount : await onGetCount!();
  }
}
