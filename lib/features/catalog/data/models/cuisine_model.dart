import '../../domain/entities/cuisine.dart';
import 'catalog_json.dart';

class CuisineModel {
  const CuisineModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.displayOrder,
    required this.isActive,
  });
  final String id;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;

  factory CuisineModel.fromJson(Object? value) {
    final json = catalogObject(value);
    return CuisineModel(
      id: catalogId(json, 'id'),
      nameAr: catalogString(json, 'nameAr'),
      nameEn: catalogString(json, 'nameEn'),
      imageUrl: catalogOptionalString(json, 'imageUrl'),
      displayOrder: catalogInt(json, 'displayOrder'),
      isActive: catalogBool(json, 'isActive'),
    );
  }

  Cuisine toDomain() => Cuisine(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        imageUrl: imageUrl,
        displayOrder: displayOrder,
        isActive: isActive,
      );
}
