import 'package:equatable/equatable.dart';

/// Only the documented fields needed by browsing. Operational status comes
/// from the server, never from the customer's clock or from [isActive].
class Store extends Equatable {
  const Store({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.mainCategoryId,
    required this.isActive,
    required this.isOpenNow,
    this.iconUrl,
    this.address,
    this.phoneNumber,
    this.mainCategoryNameAr,
    this.mainCategoryNameEn,
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

  // Optional: shown only when the API supplies them (see
  // BACKEND_MISSING_DATA.md). Nothing here is ever invented client-side.
  final double? rating;
  final int? ratingCount;
  final num? priceFrom;
  final num? priceTo;
  final num? distanceKm;
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
  List<Object?> get props => [
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
        rating,
        ratingCount,
        priceFrom,
        priceTo,
        distanceKm,
        openingHours,
      ];
}
