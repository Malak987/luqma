import 'package:equatable/equatable.dart';

/// GET snapshot only. There are no Create-only min/max/step weight fields,
/// guessed currency/unit, cart relationships, or option-price total rules.
class MenuItem extends Equatable {
  MenuItem({
    required this.id,
    required this.menuCategoryId,
    required this.menuCategoryNameAr,
    required this.menuCategoryNameEn,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.price,
    required this.compareAtPrice,
    required this.imageUrl,
    required this.isSoldByWeight,
    required this.weight,
    required this.isActive,
    List<MenuItemOption> options = const [],
    List<MenuItemAddon> addons = const [],
  })  : options = List<MenuItemOption>.unmodifiable(options),
        addons = List<MenuItemAddon>.unmodifiable(addons);

  final String id;
  final String menuCategoryId;
  final String menuCategoryNameAr;
  final String menuCategoryNameEn;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final num price;
  final num compareAtPrice;
  final String imageUrl;
  final bool isSoldByWeight;
  final num? weight;
  final bool isActive;
  final List<MenuItemOption> options;
  final List<MenuItemAddon> addons;

  bool get hasSale =>
      price.isFinite &&
      price >= 0 &&
      compareAtPrice.isFinite &&
      compareAtPrice > price;

  /// Whole-number discount between the compare-at and the current price, 0
  /// when the item is not on sale. Pure arithmetic on the two real prices.
  int get discountPercent {
    if (!hasSale) return 0;
    return ((compareAtPrice - price) / compareAtPrice * 100).round().clamp(1, 99);
  }

  @override
  List<Object?> get props => [
        id,
        menuCategoryId,
        menuCategoryNameAr,
        menuCategoryNameEn,
        nameAr,
        nameEn,
        descriptionAr,
        descriptionEn,
        price,
        compareAtPrice,
        imageUrl,
        isSoldByWeight,
        weight,
        isActive,
        options,
        addons
      ];
}

/// A selectable choice/variant. Its price is not assumed to be an additive fee.
class MenuItemOption extends Equatable {
  const MenuItemOption(
      {required this.id,
      required this.nameAr,
      required this.nameEn,
      required this.price});
  final String id;
  final String nameAr;
  final String nameEn;
  final num price;

  @override
  List<Object?> get props => [id, nameAr, nameEn, price];
}

/// Separate identity namespace and behavior from options, even if IDs coincide.
class MenuItemAddon extends Equatable {
  const MenuItemAddon(
      {required this.id,
      required this.nameAr,
      required this.nameEn,
      required this.price,
      this.imageUrl});
  final String id;
  final String nameAr;
  final String nameEn;
  final num price;
  final String? imageUrl;

  @override
  List<Object?> get props => [id, nameAr, nameEn, price, imageUrl];
}
