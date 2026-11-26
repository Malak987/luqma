import '../../domain/entities/home_ad_banner.dart';
import '../../domain/repositories/home_ads_repository.dart';
import '../datasources/home_ads_data_source.dart';

class HomeAdsRepositoryImpl implements HomeAdsRepository {
  const HomeAdsRepositoryImpl(this._dataSource);

  final HomeAdsDataSource _dataSource;

  @override
  Future<List<HomeAdBanner>> getActiveAds() async {
    final ads = await _dataSource.fetchActiveAds();
    // A banner without a renderable absolute URL is dropped here, so the
    // carousel never reserves space for an image the app cannot show.
    return List<HomeAdBanner>.unmodifiable(ads.where((ad) => _hasImage(ad)));
  }

  static bool _hasImage(HomeAdBanner ad) {
    final url = ad.imageUrl.trim();
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
