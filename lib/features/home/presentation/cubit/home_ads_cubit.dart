import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/home_ad_banner.dart';
import '../../domain/usecases/get_home_ads_use_case.dart';
import 'home_ads_state.dart';

/// Loads promotional banners on its own so an ads failure can never affect the
/// catalog, and Home can render immediately with the default banner.
class HomeAdsCubit extends Cubit<HomeAdsState> {
  HomeAdsCubit({required GetHomeAdsUseCase getHomeAdsUseCase})
      : _getHomeAdsUseCase = getHomeAdsUseCase,
        super(const HomeAdsState.initial());

  final GetHomeAdsUseCase _getHomeAdsUseCase;
  bool _requested = false;

  Future<void> load() async {
    if (isClosed || _requested) return;
    _requested = true;
    emit(state.copyWith(status: HomeAdsStatus.loading));
    try {
      final ads = await _getHomeAdsUseCase();
      if (isClosed) return;
      emit(HomeAdsState(status: HomeAdsStatus.ready, ads: ads));
    } catch (_) {
      if (isClosed) return;
      // A missing ad is not an error state for Home: fall back to the default
      // banner and stop retrying for this visit.
      emit(const HomeAdsState(status: HomeAdsStatus.ready));
    }
  }

  Future<void> refresh() async {
    _requested = false;
    await load();
  }

  /// Kept for tests and previews: render a known set of banners.
  void setAdsForTest(List<HomeAdBanner> ads) {
    _requested = true;
    emit(HomeAdsState(status: HomeAdsStatus.ready, ads: ads));
  }
}
