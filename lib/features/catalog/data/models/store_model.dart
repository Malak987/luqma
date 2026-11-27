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
    this.images = const <String>[],
    this.openTime,
    this.closeTime,
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

  /// Store photos uploaded by the owner, in API order with slot 0 preserved:
  /// `images[0]` is the card cover when it is a usable URL, and an empty string
  /// when the owner's first photo is missing or unusable.
  final List<String> images;

  /// Daily opening window as published by the API (`HH:mm:ss`). Kept verbatim;
  /// formatting is a presentation concern.
  final String? openTime;
  final String? closeTime;

  factory StoreModel.fromJson(Object? value) {
    final json = catalogObject(value);
    return StoreModel(
      id: catalogId(json, 'id'),
      nameAr: catalogName(json, 'nameAr', 'nameEn'),
      nameEn: catalogName(json, 'nameEn', 'nameAr'),
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
      priceLevel: catalogPriceLevel(json, 'priceLevel'),
      latitude: catalogOptionalNum(json, 'latitude')?.toDouble(),
      longitude: catalogOptionalNum(json, 'longitude')?.toDouble(),
      priceFrom: catalogOptionalNum(json, 'priceFrom'),
      priceTo: catalogOptionalNum(json, 'priceTo'),
      openingHours: catalogOptionalString(json, 'openingHours'),
      images: catalogStoreImages(json, 'images'),
      openTime: catalogLenientOptionalString(json, 'openTime'),
      closeTime: catalogLenientOptionalString(json, 'closeTime'),
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
        images: images,
        openTime: openTime,
        closeTime: closeTime,
      );
}
