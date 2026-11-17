import 'package:equatable/equatable.dart';

/// The exact menu-item projection supplied by the Favorites API. It is kept
/// distinct from Catalog's MenuItem because Favorite responses do not promise
/// categories, choices, add-ons or cart configuration fields.
class FavoriteMenuItem extends Equatable {
  const FavoriteMenuItem({
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

  /// Preserved as the supplied API string. The contract does not require the
  /// app to display or reinterpret its timestamp format.
  final String addedAt;

  bool get hasSale =>
      compareAtPrice != null &&
      compareAtPrice!.isFinite &&
      price.isFinite &&
      compareAtPrice! > price;

  String nameFor(bool arabic) => arabic ? nameAr : nameEn;
  String descriptionFor(bool arabic) => arabic ? descriptionAr : descriptionEn;

  @override
  List<Object?> get props => <Object?>[
        id,
        menuItemId,
        nameAr,
        nameEn,
        descriptionAr,
        descriptionEn,
        imageUrl,
        price,
        compareAtPrice,
        isAvailable,
        addedAt,
      ];
}
