import '../entities/home_ad_banner.dart';

/// Source of Home promotional banners.
///
/// The ads endpoint is not part of the approved API yet, so the shipped
/// implementation returns no banners and Home shows its built-in default banner.
/// Wiring a real endpoint later means implementing this interface only; no
/// widget or state changes are required.
abstract interface class HomeAdsRepository {
  Future<List<HomeAdBanner>> getActiveAds();
}
