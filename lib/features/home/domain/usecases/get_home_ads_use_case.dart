import '../entities/home_ad_banner.dart';
import '../repositories/home_ads_repository.dart';

class GetHomeAdsUseCase {
  const GetHomeAdsUseCase(this._repository);

  final HomeAdsRepository _repository;

  Future<List<HomeAdBanner>> call() => _repository.getActiveAds();
}
