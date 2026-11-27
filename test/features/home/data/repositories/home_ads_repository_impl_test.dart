import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/home/data/datasources/home_ads_data_source.dart';
import 'package:luqma_app/features/home/data/repositories/home_ads_repository_impl.dart';
import 'package:luqma_app/features/home/domain/entities/home_ad_banner.dart';

void main() {
  group('HomeAdsRepositoryImpl', () {
    test('the delivered data source returns no banners and makes no request',
        () async {
      // No ads endpoint is approved, so Home must fall back to its own banner
      // rather than showing an invented promotion.
      const repository = HomeAdsRepositoryImpl(NoAdsDataSource());

      expect(await repository.getActiveAds(), isEmpty);
    });

    test('passes through the banners a future source supplies', () async {
      const first = HomeAdBanner(
        id: 'ad-1',
        imageUrl: 'https://luqma-api.runasp.net/uploads/ads/one.jpg',
        title: 'Offer one',
      );
      const second = HomeAdBanner(
        id: 'ad-2',
        imageUrl: 'https://luqma-api.runasp.net/uploads/ads/two.jpg',
      );

      final repository = HomeAdsRepositoryImpl(
        _FakeDataSource(const <HomeAdBanner>[first, second]),
      );

      expect(await repository.getActiveAds(), const <HomeAdBanner>[first, second]);
    });

    test('drops banners whose image the app could not render', () async {
      final repository = HomeAdsRepositoryImpl(
        _FakeDataSource(const <HomeAdBanner>[
          HomeAdBanner(
            id: 'ok',
            imageUrl: 'https://luqma-api.runasp.net/uploads/ads/ok.jpg',
          ),
          HomeAdBanner(id: 'empty', imageUrl: ''),
          HomeAdBanner(id: 'blank', imageUrl: '   '),
          HomeAdBanner(id: 'relative', imageUrl: '/uploads/ads/x.jpg'),
          HomeAdBanner(id: 'ftp', imageUrl: 'ftp://example.test/x.jpg'),
          HomeAdBanner(id: 'no-host', imageUrl: 'https:///x.jpg'),
        ]),
      );

      final ads = await repository.getActiveAds();

      expect(ads.map((ad) => ad.id), <String>['ok']);
    });
  });
}

class _FakeDataSource implements HomeAdsDataSource {
  _FakeDataSource(this.ads);

  final List<HomeAdBanner> ads;

  @override
  Future<List<HomeAdBanner>> fetchActiveAds() async => ads;
}
