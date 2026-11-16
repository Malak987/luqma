import '../../domain/entities/cart_line.dart';
import 'cart_json.dart';

/// Verified Cart API line DTO used by mutation responses and cart items.
class CartLineModel {
  CartLineModel({
    required this.id,
    required this.menuItemId,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.menuItemOptionId,
    required this.optionNameAr,
    required this.optionNameEn,
    required this.optionPrice,
    required List<CartLineAddonModel> addons,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.isRemoved,
    required this.isAvailable,
  }) : addons = List<CartLineAddonModel>.unmodifiable(addons);

  final String id;
  final String menuItemId;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final String? menuItemOptionId;
  final String? optionNameAr;
  final String? optionNameEn;
  final num? optionPrice;
  final List<CartLineAddonModel> addons;
  final num unitPrice;
  final int quantity;
  final num lineTotal;
  final bool isRemoved;
  final bool isAvailable;

  factory CartLineModel.fromJson(Object? value) {
    final json = cartObject(value, 'cart line');
    return CartLineModel(
      id: cartRequiredString(json, 'id'),
      menuItemId: cartRequiredString(json, 'menuItemId'),
      nameAr: cartRequiredString(json, 'nameAr'),
      nameEn: cartRequiredString(json, 'nameEn'),
      imageUrl: cartOptionalString(json, 'imageUrl'),
      menuItemOptionId: cartOptionalString(json, 'menuItemOptionId'),
      optionNameAr: cartOptionalString(json, 'optionNameAr'),
      optionNameEn: cartOptionalString(json, 'optionNameEn'),
      optionPrice: cartOptionalNumber(json, 'optionPrice'),
      addons: cartRequiredList(
        json,
        'addons',
      ).map(CartLineAddonModel.fromJson).toList(growable: false),
      unitPrice: cartRequiredNumber(json, 'unitPrice'),
      quantity: cartRequiredPositiveInt(json, 'quantity'),
      lineTotal: cartRequiredNumber(json, 'lineTotal'),
      isRemoved: cartRequiredBool(json, 'isRemoved'),
      isAvailable: cartRequiredBool(json, 'isAvailable'),
    );
  }

  CartLine toDomain() => CartLine(
    id: id,
    menuItemId: menuItemId,
    nameAr: nameAr,
    nameEn: nameEn,
    imageUrl: imageUrl,
    menuItemOptionId: menuItemOptionId,
    optionNameAr: optionNameAr,
    optionNameEn: optionNameEn,
    optionPrice: optionPrice,
    addons: addons.map((addon) => addon.toDomain()).toList(growable: false),
    unitPrice: unitPrice,
    quantity: quantity,
    lineTotal: lineTotal,
    isRemoved: isRemoved,
    isAvailable: isAvailable,
  );
}

class CartLineAddonModel {
  const CartLineAddonModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final num price;

  factory CartLineAddonModel.fromJson(Object? value) {
    final json = cartObject(value, 'cart line addon');
    return CartLineAddonModel(
      id: cartRequiredString(json, 'id'),
      nameAr: cartRequiredString(json, 'nameAr'),
      nameEn: cartRequiredString(json, 'nameEn'),
      price: cartRequiredNumber(json, 'price'),
    );
  }

  CartLineAddon toDomain() =>
      CartLineAddon(id: id, nameAr: nameAr, nameEn: nameEn, price: price);
}
