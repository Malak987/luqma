import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/translations/home_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../catalog/domain/entities/store.dart';
import '../../../catalog/presentation/widgets/store_card.dart';
import '../cubit/home_state.dart';
import 'home_section.dart';

class HomeRestaurantsSection extends StatelessWidget {
  const HomeRestaurantsSection({
    required this.restaurants,
    this.status = HomeRestaurantsStatus.success,
    this.onRetry,
    this.onStoreTap,
    this.onSeeAll,
    super.key,
  });

  static const double _cardWidth = 220;
  static const double _listHeight = 260;

  final List<Store> restaurants;
  final HomeRestaurantsStatus status;
  final VoidCallback? onRetry;
  final ValueChanged<Store>? onStoreTap;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = l10n.home;
    final arabic = l10n.locale.languageCode == 'ar';

    return HomeSection(
      title: copy.restaurantsTitle,
      subtitle: copy.restaurantsSubtitle,
      seeAllLabel: copy.seeAll,
      onSeeAll: onSeeAll,
      child: _content(context, copy, arabic),
    );
  }

  Widget _content(BuildContext context, HomeTranslations copy, bool arabic) {
    switch (status) {
      case HomeRestaurantsStatus.initial:
      case HomeRestaurantsStatus.loading:
        final theme = Theme.of(context);
        final colors =
            theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
        final media = MediaQuery.of(context);
        final reduceMotion = media.disableAnimations || media.accessibleNavigation;
        return Card(
          key: const Key('home_restaurants_loading'),
          color: colors.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: reduceMotion
                  ? Semantics(
                      liveRegion: true,
                      label: copy.restaurantsLoading,
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        color: colors.primary,
                        size: AppSizes.iconMedium,
                      ),
                    )
                  : CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      semanticsLabel: copy.restaurantsLoading,
                    ),
            ),
          ),
        );
      case HomeRestaurantsStatus.error:
        return HomeSectionPlaceholder(
          key: const Key('home_restaurants_error'),
          icon: Icons.cloud_off_outlined,
          message: copy.restaurantsLoadFailed,
          action: SizedBox(
            width: 220,
            child: AppButton(
              key: const Key('home_restaurants_retry'),
              text: copy.retry,
              onPressed: onRetry,
            ),
          ),
        );
      case HomeRestaurantsStatus.unavailable:
        return HomeSectionPlaceholder(
          key: const Key('home_restaurants_unavailable'),
          icon: Icons.storefront_outlined,
          message: copy.restaurantsCategoryUnavailable,
        );
      case HomeRestaurantsStatus.empty:
        return HomeSectionPlaceholder(
          key: const Key('home_restaurants_empty'),
          icon: Icons.restaurant_outlined,
          message: copy.restaurantsEmpty,
        );
      case HomeRestaurantsStatus.success:
        if (restaurants.isEmpty) {
          return HomeSectionPlaceholder(
            key: const Key('home_restaurants_empty'),
            icon: Icons.restaurant_outlined,
            message: copy.restaurantsEmpty,
          );
        }
        return SizedBox(
          key: const Key('home_restaurants_results'),
          height: _listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: restaurants.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final store = restaurants[index];
              return SizedBox(
                width: _cardWidth,
                child: StoreCard(
                  name: arabic ? store.nameAr : store.nameEn,
                  imageUrl: store.iconUrl,
                  address: store.address,
                  categoryName: arabic
                      ? store.mainCategoryNameAr
                      : store.mainCategoryNameEn,
                  isOpenNow: store.isOpenNow,
                  onTap: onStoreTap == null ? () {} : () => onStoreTap!(store),
                ),
              );
            },
          ),
        );
    }
  }
}
