import '../../domain/entities/menu_category.dart';
import 'catalog_json.dart';

class MenuCategoryModel {
  const MenuCategoryModel(
      {required this.id,
      required this.storeId,
      required this.nameAr,
      required this.nameEn,
      required this.imageUrl,
      required this.displayOrder,
      required this.isActive,
      required this.itemsCount});
  final String id;
  final String storeId;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;
  final int itemsCount;

  factory MenuCategoryModel.fromJson(Object? value) {
    final json = catalogObject(value);
    final count = catalogInt(json, 'itemsCount');
    if (count < 0)
      throw const FormatException('Invalid menu category item count');
    return MenuCategoryModel(
        id: catalogId(json, 'id'),
        storeId: catalogId(json, 'storeId'),
        nameAr: catalogString(json, 'nameAr'),
        nameEn: catalogString(json, 'nameEn'),
        imageUrl: catalogOptionalString(json, 'imageUrl'),
        displayOrder: catalogInt(json, 'displayOrder'),
        isActive: catalogBool(json, 'isActive'),
        itemsCount: count);
  }

  MenuCategory toDomain() => MenuCategory(
      id: id,
      storeId: storeId,
      nameAr: nameAr,
      nameEn: nameEn,
      imageUrl: imageUrl,
      displayOrder: displayOrder,
      isActive: isActive,
      itemsCount: itemsCount);
}
