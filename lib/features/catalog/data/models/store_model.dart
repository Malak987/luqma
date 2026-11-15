import '../../domain/entities/store.dart';
import 'catalog_json.dart';

/// A deliberate subset of the documented Store GET response. In particular,
/// the shape of nested `cuisines` is NOT inferred from Cuisine/GetAll.
class StoreModel {
  const StoreModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.mainCategoryId,
    required this.isActive,
    required this.isOpenNow,
    required this.iconUrl,
    required this.address,
    required this.phoneNumber,
    required this.mainCategoryNameAr,
    required this.mainCategoryNameEn,
    this.rating,
    this.ratingCount,
    this.priceFrom,
    this.priceTo,
    this.distanceKm,
    this.openingHours,
  });
  final String id;
  final String nameAr;
  final String nameEn;
  final String mainCategoryId;
  final bool isActive;
  final bool isOpenNow;
  final String? iconUrl;
  final String? address;
  final String? phoneNumber;
  final String? mainCategoryNameAr;
  final String? mainCategoryNameEn;
  final double? rating;
  final int? ratingCount;
  final num? priceFrom;
  final num? priceTo;
  final num? distanceKm;
  final String? openingHours;

  factory StoreModel.fromJson(Object? value) {
    final json = catalogObject(value);
    return StoreModel(
      id: catalogId(json, 'id'),
      nameAr: catalogString(json, 'nameAr'),
      nameEn: catalogString(json, 'nameEn'),
      mainCategoryId: catalogId(json, 'mainCategoryId'),
      isActive: catalogBool(json, 'isActive'),
      isOpenNow: catalogBool(json, 'isOpenNow'),
      iconUrl: catalogOptionalString(json, 'iconUrl'),
      address: catalogOptionalString(json, 'address'),
      phoneNumber: catalogOptionalString(json, 'phoneNumber'),
      mainCategoryNameAr: catalogOptionalString(json, 'mainCategoryNameAr'),
      mainCategoryNameEn: catalogOptionalString(json, 'mainCategoryNameEn'),
      // Proposed contract keys; absent today, so they parse to null.
      rating: catalogOptionalNum(json, 'rating')?.toDouble(),
      ratingCount: catalogOptionalNum(json, 'ratingCount')?.toInt(),
      priceFrom: catalogOptionalNum(json, 'priceFrom'),
      priceTo: catalogOptionalNum(json, 'priceTo'),
      distanceKm: catalogOptionalNum(json, 'distanceKm'),
      openingHours: json['openingHours'] is String
          ? catalogOptionalString(json, 'openingHours')
          : null,
    );
  }

  Store toDomain() => Store(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        mainCategoryId: mainCategoryId,
        isActive: isActive,
        isOpenNow: isOpenNow,
        iconUrl: iconUrl,
        address: address,
        phoneNumber: phoneNumber,
        mainCategoryNameAr: mainCategoryNameAr,
        mainCategoryNameEn: mainCategoryNameEn,
        rating: rating,
        ratingCount: ratingCount,
        priceFrom: priceFrom,
        priceTo: priceTo,
        distanceKm: distanceKm,
        openingHours: openingHours,
      );
}
