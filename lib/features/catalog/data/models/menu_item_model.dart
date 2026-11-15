import '../../domain/entities/menu_item.dart';
import 'catalog_json.dart';
import 'menu_json.dart';

class MenuItemModel {
  MenuItemModel({
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
    required List<MenuItemOptionModel> options,
    required List<MenuItemAddonModel> addons,
  })  : options = List<MenuItemOptionModel>.unmodifiable(options),
        addons = List<MenuItemAddonModel>.unmodifiable(addons);
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
  final List<MenuItemOptionModel> options;
  final List<MenuItemAddonModel> addons;

  factory MenuItemModel.fromJson(Object? value) {
    final json = catalogObject(value);
    return MenuItemModel(
      id: catalogId(json, 'id'),
      menuCategoryId: catalogId(json, 'menuCategoryId'),
      menuCategoryNameAr: menuText(json, 'menuCategoryNameAr'),
      menuCategoryNameEn: menuText(json, 'menuCategoryNameEn'),
      nameAr: catalogString(json, 'nameAr'),
      nameEn: catalogString(json, 'nameEn'),
      descriptionAr: menuText(json, 'descriptionAr'),
      descriptionEn: menuText(json, 'descriptionEn'),
      price: menuNumber(json, 'price'),
      compareAtPrice: menuNumber(json, 'compareAtPrice'),
      imageUrl: menuText(json, 'imageUrl'),
      isSoldByWeight: catalogBool(json, 'isSoldByWeight'),
      weight: menuOptionalNumber(json, 'weight'),
      isActive: catalogBool(json, 'isActive'),
      options: menuOptionalArray(json, 'options')
          .map(MenuItemOptionModel.fromJson)
          .toList(growable: false),
      addons: menuOptionalArray(json, 'addons')
          .map(MenuItemAddonModel.fromJson)
          .toList(growable: false),
    );
  }

  MenuItem toDomain() => MenuItem(
      id: id,
      menuCategoryId: menuCategoryId,
      menuCategoryNameAr: menuCategoryNameAr,
      menuCategoryNameEn: menuCategoryNameEn,
      nameAr: nameAr,
      nameEn: nameEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      price: price,
      compareAtPrice: compareAtPrice,
      imageUrl: imageUrl,
      isSoldByWeight: isSoldByWeight,
      weight: weight,
      isActive: isActive,
      options:
          options.map((option) => option.toDomain()).toList(growable: false),
      addons: addons.map((addon) => addon.toDomain()).toList(growable: false));
}

class MenuItemOptionModel {
  const MenuItemOptionModel(
      {required this.id,
      required this.nameAr,
      required this.nameEn,
      required this.price});
  final String id;
  final String nameAr;
  final String nameEn;
  final num price;

  factory MenuItemOptionModel.fromJson(Object? value) {
    final json = catalogObject(value);
    return MenuItemOptionModel(
        id: catalogString(json, 'id'),
        nameAr: catalogString(json, 'nameAr'),
        nameEn: catalogString(json, 'nameEn'),
        price: menuNumber(json, 'price'));
  }
  MenuItemOption toDomain() =>
      MenuItemOption(id: id, nameAr: nameAr, nameEn: nameEn, price: price);
}

class MenuItemAddonModel {
  const MenuItemAddonModel(
      {required this.id,
      required this.nameAr,
      required this.nameEn,
      required this.price,
      required this.imageUrl});
  final String id;
  final String nameAr;
  final String nameEn;
  final num price;
  final String? imageUrl;

  factory MenuItemAddonModel.fromJson(Object? value) {
    final json = catalogObject(value);
    return MenuItemAddonModel(
        id: catalogString(json, 'id'),
        nameAr: catalogString(json, 'nameAr'),
        nameEn: catalogString(json, 'nameEn'),
        price: menuNumber(json, 'price'),
        imageUrl: catalogOptionalString(json, 'imageUrl'));
  }
  MenuItemAddon toDomain() => MenuItemAddon(
      id: id, nameAr: nameAr, nameEn: nameEn, price: price, imageUrl: imageUrl);
}
