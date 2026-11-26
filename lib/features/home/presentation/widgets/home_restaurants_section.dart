import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/translations/home_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../catalog/domain/entities/store.dart';
import '../../../catalog/presentation/widgets/store_card.dart';
import '../../../catalog/presentation/widgets/store_status_badge.dart';
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

  final List<Store> restaurants;
  final HomeRestaurantsStatus status;
  final VoidCallback? onRetry;
  final ValueChanged<Store>? onStoreTap;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).home;
    return HomeSection(
      title: copy.restaurantsTitle,
      subtitle: copy.restaurantsSubtitle,
      seeAllLabel: copy.seeAll,
      onSeeAll: onSeeAll,
      child: _content(context, copy),
    );
  }

  Widget _content(BuildContext context, HomeTranslations copy) {
    switch (status) {
      case HomeRestaurantsStatus.initial:
      case HomeRestaurantsStatus.loading:
        final theme = Theme.of(context);
        final colors = theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
        final reduceMotion = MediaQuery.of(context).disableAnimations ||
            MediaQuery.of(context).accessibleNavigation;
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
                      child: Icon(Icons.hourglass_empty_rounded,
                          color: colors.primary, size: AppSizes.iconMedium),
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
      case HomeRestaurantsStatus.success:
        if (restaurants.isEmpty) {
          return HomeSectionPlaceholder(
            key: const Key('home_restaurants_empty'),
            icon: Icons.restaurant_outlined,
            message: copy.restaurantsEmpty,
          );
        }
        return _RestaurantLayout(
          restaurants: restaurants,
          onStoreTap: onStoreTap,
        );
    }
  }
}

class _RestaurantLayout extends StatelessWidget {
  const _RestaurantLayout({required this.restaurants, this.onStoreTap});

  final List<Store> restaurants;
  final ValueChanged<Store>? onStoreTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.sm;
        final smallWidth = (constraints.maxWidth - gap) / 2;
        return Column(
          key: const Key('home_restaurants_results'),
          children: [
            _FeaturedRestaurantCard(
              store: restaurants.first,
              onTap: onStoreTap == null ? null : () => onStoreTap!(restaurants.first),
            ),
            if (restaurants.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: gap,
                runSpacing: AppSpacing.md,
                children: [
                  for (final store in restaurants.skip(1))
                    SizedBox(
                      width: smallWidth,
                      child: _CompactRestaurantCard(
                        store: store,
                        onTap: onStoreTap == null ? null : () => onStoreTap!(store),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FeaturedRestaurantCard extends StatelessWidget {
  const _FeaturedRestaurantCard({required this.store, this.onTap});
  final Store store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isArabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final name = isArabic ? store.nameAr : store.nameEn;
    final category = isArabic
        ? (store.mainCategoryNameAr ?? store.mainCategoryNameEn)
        : (store.mainCategoryNameEn ?? store.mainCategoryNameAr);

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _RestaurantLogo(store: store, size: 104, radius: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.headingText, fontWeight: FontWeight.w800)),
                    if (category?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(category!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.mutedText)),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _RestaurantMetadata(store: store),
                    if (store.isOpenNow != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      StoreStatusBadge(isOpenNow: store.isOpenNow!),
                    ],
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactRestaurantCard extends StatelessWidget {
  const _CompactRestaurantCard({required this.store, this.onTap});
  final Store store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isArabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final name = isArabic ? store.nameAr : store.nameEn;
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.largeRadius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _RestaurantLogo(store: store, size: 76, radius: 18)),
              const SizedBox(height: AppSpacing.sm),
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.headingText, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.xs),
              _RestaurantMetadata(store: store),
              if (store.isOpenNow != null) ...[
                const SizedBox(height: AppSpacing.xs),
                StoreStatusBadge(isOpenNow: store.isOpenNow!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantLogo extends StatelessWidget {
  const _RestaurantLogo({required this.store, required this.size, required this.radius});
  final Store store;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.border.withValues(alpha: .75)),
      ),
      child: AppNetworkImage(
        url: store.iconUrl,
        fit: BoxFit.contain,
        placeholder: const StoreArtworkPlaceholder(),
      ),
    );
  }
}

class _RestaurantMetadata extends StatelessWidget {
  const _RestaurantMetadata({required this.store});
  final Store store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    final rating = store.averageRating;
    final hasRating = rating != null && rating.isFinite && rating >= 0 &&
        rating <= 5 && (store.ratingsCount ?? 0) > 0;
    final minutes = store.deliveryTimeMinutes;
    final fee = store.deliveryFee;
    final items = <Widget>[
      if (hasRating) _meta(Icons.star_rounded, copy.number(double.parse(rating.toStringAsFixed(1))), colors.accent, theme, colors),
      if (minutes != null && minutes > 0) _meta(Icons.schedule_rounded, copy.deliveryMinutes(minutes), colors.primary, theme, colors),
      if (fee != null && fee >= 0) _meta(Icons.delivery_dining_rounded, copy.deliveryFee(fee), colors.primary, theme, colors),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xxs, children: items);
  }

  Widget _meta(IconData icon, String text, Color iconColor, ThemeData theme, AppSemanticColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 3),
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: colors.mutedText)),
      ],
    );
  }
}
