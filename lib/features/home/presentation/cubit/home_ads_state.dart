import 'package:equatable/equatable.dart';

import '../../domain/entities/home_ad_banner.dart';

enum HomeAdsStatus { initial, loading, ready }

/// Ads never block Home: whatever the outcome, the promo area keeps its space
/// and shows the default banner when [ads] is empty.
class HomeAdsState extends Equatable {
  const HomeAdsState({
    this.status = HomeAdsStatus.initial,
    this.ads = const <HomeAdBanner>[],
  });

  const HomeAdsState.initial() : this();

  final HomeAdsStatus status;
  final List<HomeAdBanner> ads;

  bool get hasAds => ads.isNotEmpty;

  HomeAdsState copyWith({
    HomeAdsStatus? status,
    List<HomeAdBanner>? ads,
  }) {
    return HomeAdsState(
      status: status ?? this.status,
      ads: ads ?? this.ads,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, ads];
}
