import 'package:equatable/equatable.dart';

/// A cart line returned by the Cart API.
///
/// Prices and availability are server-provided snapshots. They are deliberately
/// not calculated from a catalog [MenuItem] because the Cart service owns its
/// pricing rules.
class CartLine extends Equatable {
  CartLine({
    required this.id,
    required this.menuItemId,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.menuItemOptionId,
    required this.optionNameAr,
    required this.optionNameEn,
    required this.optionPrice,
    required List<CartLineAddon> addons,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.isRemoved,
    required this.isAvailable,
  }) : addons = List<CartLineAddon>.unmodifiable(addons);

  /// Backend cart-line identifier. It is display data only: UpdateToCart does
  /// not accept it, so clients must never send it as an undocumented field.
  final String id;
  final String menuItemId;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final String? menuItemOptionId;
  final String? optionNameAr;
  final String? optionNameEn;
  final num? optionPrice;
  final List<CartLineAddon> addons;
  final num unitPrice;
  final int quantity;
  final num lineTotal;
  final bool isRemoved;
  final bool isAvailable;

  String nameFor(bool arabic) => arabic ? nameAr : nameEn;

  String? optionNameFor(bool arabic) => arabic ? optionNameAr : optionNameEn;

  CartLine copyWith({int? quantity, num? lineTotal}) => CartLine(
    id: id,
    menuItemId: menuItemId,
    nameAr: nameAr,
    nameEn: nameEn,
    imageUrl: imageUrl,
    menuItemOptionId: menuItemOptionId,
    optionNameAr: optionNameAr,
    optionNameEn: optionNameEn,
    optionPrice: optionPrice,
    addons: addons,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
    lineTotal: lineTotal ?? this.lineTotal,
    isRemoved: isRemoved,
    isAvailable: isAvailable,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    menuItemId,
    nameAr,
    nameEn,
    imageUrl,
    menuItemOptionId,
    optionNameAr,
    optionNameEn,
    optionPrice,
    addons,
    unitPrice,
    quantity,
    lineTotal,
    isRemoved,
    isAvailable,
  ];
}

/// A selected add-on as returned with a cart line.
class CartLineAddon extends Equatable {
  const CartLineAddon({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final num price;

  String nameFor(bool arabic) => arabic ? nameAr : nameEn;

  @override
  List<Object?> get props => <Object?>[id, nameAr, nameEn, price];
}
