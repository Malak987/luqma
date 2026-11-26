import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/home/domain/entities/home_ad_banner.dart';
import 'package:luqma_app/features/home/domain/usecases/get_home_ads_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_ads_cubit.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_ads_state.dart';

void main() {
  group('HomeAdsCubit', () {
    test('starts empty so Home renders its default banner immediately', () {
      final cubit = HomeAdsCubit(getHomeAdsUseCase: _FakeGetAds());
      expect(cubit.state.status, HomeAdsStatus.initial);
      expect(cubit.state.hasAds, isFalse);
      cubit.close();
    });

    test('emits the ads a source returns', () async {
      const ad = HomeAdBanner(
        id: 'ad-1',
        imageUrl: 'https://luqma-api.runasp.net/uploads/ads/one.jpg',
      );
      final cubit = HomeAdsCubit(
        getHomeAdsUseCase: _FakeGetAds(ads: const <HomeAdBanner>[ad]),
      );

      await cubit.load();

      expect(cubit.state.status, HomeAdsStatus.ready);
      expect(cubit.state.ads, const <HomeAdBanner>[ad]);
      expect(cubit.state.hasAds, isTrue);
      await cubit.close();
    });

    test('an empty source keeps the default banner without an error state',
        () async {
      final cubit = HomeAdsCubit(getHomeAdsUseCase: _FakeGetAds());
      await cubit.load();

      expect(cubit.state.status, HomeAdsStatus.ready);
      expect(cubit.state.ads, isEmpty);
      await cubit.close();
    });

    test('a failing source falls back to the default banner', () async {
      final cubit = HomeAdsCubit(
        getHomeAdsUseCase: _FakeGetAds(
          failure: const FailureException(
            Failure(FailureCode.network, debugMessage: 'offline'),
          ),
        ),
      );

      await cubit.load();

      expect(cubit.state.status, HomeAdsStatus.ready);
      expect(cubit.state.hasAds, isFalse);
      await cubit.close();
    });

    test('requests the source once per visit', () async {
      final useCase = _FakeGetAds();
      final cubit = HomeAdsCubit(getHomeAdsUseCase: useCase);

      await cubit.load();
      await cubit.load();

      expect(useCase.calls, 1);
      await cubit.close();
    });
  });
}

class _FakeGetAds implements GetHomeAdsUseCase {
  _FakeGetAds({this.ads = const <HomeAdBanner>[], this.failure});

  final List<HomeAdBanner> ads;
  final FailureException? failure;
  int calls = 0;

  @override
  Future<List<HomeAdBanner>> call() async {
    calls++;
    if (failure != null) throw failure!;
    return ads;
  }
}
