import '../../domain/entities/favorite_menu_item.dart';
import '../../domain/queries/favorite_identifiers.dart';
import 'favorite_json.dart';

/// Favorite API item projection. It intentionally does not claim menu fields
/// that GetMyFavorites does not return, such as options or category metadata.
class FavoriteMenuItemModel {
  const FavoriteMenuItemModel({
    required this.id,
    required this.menuItemId,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.imageUrl,
    required this.price,
    required this.compareAtPrice,
    required this.isAvailable,
    required this.addedAt,
  });

  final String id;
  final String menuItemId;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String? imageUrl;
  final num price;
  final num? compareAtPrice;
  final bool isAvailable;
  final String addedAt;

  factory FavoriteMenuItemModel.fromJson(Object? value) {
    final json = favoriteObject(value, 'favorite menu item');
    final id = favoriteRequiredString(json, 'id');
    final menuItemId = favoriteRequiredString(json, 'menuItemId');
    if (!isFavoriteMenuItemId(id) || !isFavoriteMenuItemId(menuItemId)) {
      throw const FormatException('Invalid favorite menu item identifier');
    }
    return FavoriteMenuItemModel(
      id: id,
      menuItemId: menuItemId,
      nameAr: favoriteRequiredString(json, 'nameAr'),
      nameEn: favoriteRequiredString(json, 'nameEn'),
      descriptionAr: favoriteText(json, 'descriptionAr'),
      descriptionEn: favoriteText(json, 'descriptionEn'),
      imageUrl: favoriteOptionalString(json, 'imageUrl'),
      price: favoriteRequiredNumber(json, 'price'),
      compareAtPrice: favoriteOptionalNumber(json, 'compareAtPrice'),
      isAvailable: favoriteRequiredBool(json, 'isAvailable'),
      addedAt: favoriteRequiredString(json, 'addedAt'),
    );
  }

  FavoriteMenuItem toDomain() => FavoriteMenuItem(
        id: id,
        menuItemId: menuItemId,
        nameAr: nameAr,
        nameEn: nameEn,
        descriptionAr: descriptionAr,
        descriptionEn: descriptionEn,
        imageUrl: imageUrl,
        price: price,
        compareAtPrice: compareAtPrice,
        isAvailable: isAvailable,
        addedAt: addedAt,
      );
}
