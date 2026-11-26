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

  /// Photos uploaded by the store owner, in API order. Slot 0 is preserved by
  /// the mapper, so `images[0]` is always the owner's first photo (an empty
  /// string when it is unusable). [coverImageUrl] uses only that slot;
  /// [iconUrl] stays the separate logo artwork.
  final List<String> images;

  /// Published opening window (`HH:mm:ss`), shown next to the open/closed
  /// status. Null means the store did not publish hours.
  final String? openTime;
  final String? closeTime;

  /// Cover artwork for cards, in a strict priority:
  ///
  /// 1. `images[0]` when it is a usable absolute URL,
  /// 2. [iconUrl] when `images[0]` is missing, blank or unusable,
  /// 3. null — the card then draws its Luqma placeholder.
  ///
  /// The list is deliberately never scanned: a second photo is not a fallback
  /// for a broken first one, so the cover is always the artwork the owner
  /// listed first, never a silent pick from the middle of the gallery.
  String? get coverImageUrl {
    final first = images.isEmpty ? null : images.first;
    if (_isUsableImageUrl(first)) return first!.trim();
    final icon = iconUrl;
    if (_isUsableImageUrl(icon)) return icon!.trim();
    return null;
  }

  /// True when the cover comes from `images[0]`, so the card shows the logo as a
  /// separate badge instead of repeating it inside the cover.
  bool get hasUploadedCover =>
      _isUsableImageUrl(images.isEmpty ? null : images.first);

  /// True when the store publishes usable coordinates. `0, 0` is the API's
  /// "not provided" placeholder and is never treated as a real position.
  bool get hasUsableCoordinates {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0 && lng == 0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    return true;
  }

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
        images,
        openTime,
        closeTime,
      ];
}

/// An absolute `http`/`https` URL the app can actually request.
///
/// Mirrors the contract of the shared network image widget: no whitespace, a
/// real scheme and a host. Anything else counts as "unavailable" so the cover
/// falls to the next priority instead of rendering a broken box.
bool _isUsableImageUrl(String? value) {
  final url = value?.trim() ?? '';
  if (url.isEmpty || url.contains(_imageUrlWhitespace)) return false;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  return uri.host.isNotEmpty;
}

final RegExp _imageUrlWhitespace = RegExp(r'\s');
