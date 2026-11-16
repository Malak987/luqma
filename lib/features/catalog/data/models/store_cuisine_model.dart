import '../../domain/entities/store_cuisine.dart';
import 'catalog_json.dart';

/// The small cuisine projection embedded in Store/GetAll responses.
///
/// It is deliberately separate from the filter `CuisineModel`: Store responses only need
/// localized display names and must not require the filter endpoint's ID,
/// display order, or active-state fields.
class StoreCuisineModel {
  const StoreCuisineModel({this.nameAr, this.nameEn});

  final String? nameAr;
  final String? nameEn;

  /// An optional nested collection must never make the surrounding Store
  /// unreadable. Entries without any usable localized name are ignored.
  static List<StoreCuisineModel> listFromJson(Object? value) {
    if (value is! List<Object?>) return const <StoreCuisineModel>[];

    return List<StoreCuisineModel>.unmodifiable(value
        .map(tryFromJson)
        .whereType<StoreCuisineModel>()
        .toList(growable: false));
  }

  static StoreCuisineModel? tryFromJson(Object? value) {
    if (value is! Map<Object?, Object?> ||
        value.keys.any((key) => key is! String)) {
      return null;
    }

    final nameAr = catalogLenientOptionalString(value, 'nameAr');
    final nameEn = catalogLenientOptionalString(value, 'nameEn');
    if (nameAr == null && nameEn == null) return null;
    return StoreCuisineModel(nameAr: nameAr, nameEn: nameEn);
  }

  StoreCuisine toDomain() => StoreCuisine(nameAr: nameAr, nameEn: nameEn);
}
