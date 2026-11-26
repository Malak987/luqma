import '../../domain/entities/home_ad_banner.dart';

/// Transport-level source of promotional banners.
abstract interface class HomeAdsDataSource {
  Future<List<HomeAdBanner>> fetchActiveAds();
}

/// The delivered implementation while no ads endpoint exists.
///
/// It performs no request: calling a path the backend does not serve would be
/// an invented endpoint. Returning an empty list makes Home fall back to the
/// default banner, which is the documented behaviour.
final class NoAdsDataSource implements HomeAdsDataSource {
  const NoAdsDataSource();

  @override
  Future<List<HomeAdBanner>> fetchActiveAds() async =>
      const <HomeAdBanner>[];
}
