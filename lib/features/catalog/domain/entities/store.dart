import 'package:equatable/equatable.dart';

import 'store_cuisine.dart';

/// Store snapshot supplied by the customer-facing Store API.
///
/// Operational status always comes from [isOpenNow] when supplied by the
/// server. A missing status stays null; it must not be interpreted as closed.
class Store extends Equatable {
  const Store({
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
    this.cuisines = const <StoreCuisine>[],
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
  final List<StoreCuisine> cuisines;
  final double? averageRating;
  final int? ratingsCount;
  final num? distanceKm;
  final int? deliveryTimeMinutes;
  final num? deliveryFee;
  final String? priceLevel;
  final double? latitude;
  final double? longitude;

  // Used by the existing Store price-range filter/details snapshot. These
  // values are intentionally separate from the API's display price level.
  final num? priceFrom;
  final num? priceTo;
  final String? openingHours;

  /// True when the store's price band overlaps [min]..[max]. A store that
  /// publishes no price data is never hidden by a price filter.
  bool matchesPriceRange(num min, num max) {
    if (priceFrom == null && priceTo == null) return true;
    final low = priceFrom ?? priceTo!;
    final high = priceTo ?? priceFrom!;
    return low <= max && high >= min;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        nameAr,
        nameEn,
        mainCategoryId,
        isActive,
        isOpenNow,
        iconUrl,
        address,
        phoneNumber,
        mainCategoryNameAr,
        mainCategoryNameEn,
        descriptionAr,
        descriptionEn,
        cuisines,
        averageRating,
        ratingsCount,
        distanceKm,
        deliveryTimeMinutes,
        deliveryFee,
        priceLevel,
        latitude,
        longitude,
        priceFrom,
        priceTo,
        openingHours,
      ];
}
