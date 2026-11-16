import '../../domain/entities/store.dart';
import 'catalog_json.dart';
import 'store_cuisine_model.dart';

/// Store/GetAll response model.
///
/// Every optional card field is decoded from the Store response itself. Missing
/// or invalid optional display data remains null so the UI can omit it instead
/// of fabricating a default.
class StoreModel {
  const StoreModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.mainCategoryId,
    required this.isActive,
    this.isOpenNow,
    this.iconUrl,
    this.address,
    this.phoneNumber,
    this.mainCategoryNameAr,
    this.mainCategoryNameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.cuisines = const <StoreCuisineModel>[],
    this.averageRating,
    this.ratingsCount,
    this.distanceKm,
    this.deliveryTimeMinutes,
    this.deliveryFee,
    this.priceLevel,
    this.latitude,
    this.longitude,
    this.priceFrom,
    this.priceTo,
    this.openingHours,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String mainCategoryId;
  final bool isActive;
  final bool? isOpenNow;
  final String? iconUrl;
  final String? address;
  final String? phoneNumber;
  final String? mainCategoryNameAr;
  final String? mainCategoryNameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final List<StoreCuisineModel> cuisines;
  final double? averageRating;
  final int? ratingsCount;
  final num? distanceKm;
  final int? deliveryTimeMinutes;
  final num? deliveryFee;
  final String? priceLevel;
  final double? latitude;
  final double? longitude;

  // Existing optional Store values retained for the price-range filter and
  // store-details snapshot. They are not repurposed as a price level.
  final num? priceFrom;
  final num? priceTo;
  final String? openingHours;

  factory StoreModel.fromJson(Object? value) {
    final json = catalogObject(value);
    return StoreModel(
      id: catalogId(json, 'id'),
      nameAr: catalogString(json, 'nameAr'),
      nameEn: catalogString(json, 'nameEn'),
      mainCategoryId: catalogId(json, 'mainCategoryId'),
      isActive: catalogBool(json, 'isActive'),
      isOpenNow: catalogOptionalBool(json, 'isOpenNow'),
      iconUrl: catalogOptionalString(json, 'iconUrl'),
      address: catalogOptionalString(json, 'address'),
      phoneNumber: catalogOptionalString(json, 'phoneNumber'),
      mainCategoryNameAr: catalogOptionalString(json, 'mainCategoryNameAr'),
      mainCategoryNameEn: catalogOptionalString(json, 'mainCategoryNameEn'),
      descriptionAr: catalogOptionalString(json, 'descriptionAr'),
      descriptionEn: catalogOptionalString(json, 'descriptionEn'),
      cuisines: StoreCuisineModel.listFromJson(json['cuisines']),
      averageRating: catalogOptionalNum(json, 'averageRating')?.toDouble(),
      ratingsCount: catalogOptionalInt(json, 'ratingsCount'),
      distanceKm: catalogOptionalNum(json, 'distanceKm'),
      deliveryTimeMinutes: catalogOptionalInt(json, 'deliveryTimeMinutes'),
      deliveryFee: catalogOptionalNum(json, 'deliveryFee'),
      // The contract's display representation is textual. Numeric/enum values
      // are deliberately hidden until the backend defines their mapping.
      priceLevel: catalogLenientOptionalString(json, 'priceLevel'),
      latitude: catalogOptionalNum(json, 'latitude')?.toDouble(),
      longitude: catalogOptionalNum(json, 'longitude')?.toDouble(),
      priceFrom: catalogOptionalNum(json, 'priceFrom'),
      priceTo: catalogOptionalNum(json, 'priceTo'),
      openingHours: catalogOptionalString(json, 'openingHours'),
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
        descriptionAr: descriptionAr,
        descriptionEn: descriptionEn,
        cuisines: cuisines.map((cuisine) => cuisine.toDomain()).toList(),
        averageRating: averageRating,
        ratingsCount: ratingsCount,
        distanceKm: distanceKm,
        deliveryTimeMinutes: deliveryTimeMinutes,
        deliveryFee: deliveryFee,
        priceLevel: priceLevel,
        latitude: latitude,
        longitude: longitude,
        priceFrom: priceFrom,
        priceTo: priceTo,
        openingHours: openingHours,
      );
}
