
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
import '../cubit/home_state.dart';
import '../utils/home_layout.dart';
import 'home_section.dart';

class HomeRestaurantsSection extends StatelessWidget {
  const HomeRestaurantsSection({
    required this.restaurants,
    this.status = HomeRestaurantsStatus.success,
    this.onRetry,
    this.onStoreTap,
    this.onSeeAll,
    this.hasActiveOffers,
    super.key,
  });

  final List<Store> restaurants;
  final HomeRestaurantsStatus status;
  final VoidCallback? onRetry;
  final ValueChanged<Store>? onStoreTap;
  final VoidCallback? onSeeAll;

  /// Returns true only when the store has at least one active offer.
  ///
  /// Keep null until the offers API is integrated.
  final bool Function(Store store)? hasActiveOffers;

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
        final colors =
            theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

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
          onShowMore: onSeeAll,
          hasActiveOffers: hasActiveOffers,
        );
    }
  }
}

/// Three cards, one per row, followed by the optional "Show more" button.
class _RestaurantLayout extends StatelessWidget {
  const _RestaurantLayout({
    required this.restaurants,
    this.onStoreTap,
    this.onShowMore,
    this.hasActiveOffers,
  });

  static const int _maxCards = 3;

  final List<Store> restaurants;
  final ValueChanged<Store>? onStoreTap;
  final VoidCallback? onShowMore;
  final bool Function(Store store)? hasActiveOffers;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).home;
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    final shown = restaurants.take(_maxCards).toList(growable: false);

    return Column(
      key: const Key('home_restaurants_results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _RestaurantCard(
            store: shown[i],
            featured: true,
            hasActiveOffers:
            hasActiveOffers?.call(shown[i]) ?? false,
            onTap: onStoreTap == null ? null : () => onStoreTap!(shown[i]),
          ),
        ],
        if (onShowMore != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            key: const Key('home_restaurants_show_more'),
            onPressed: onShowMore,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
              side: BorderSide(
                color: colors.primary.withValues(alpha: .5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.showMore,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Restaurant card:
/// - Cover image.
/// - Optional offer badge.
/// - Open/closed status.
/// - Overlapping restaurant logo.
/// - Name and main category.
/// - Cuisine pills.
/// - Rating, delivery time, and delivery fee.
class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.store,
    required this.featured,
    this.hasActiveOffers = false,
    this.onTap,
  });

  final Store store;
  final bool featured;
  final bool hasActiveOffers;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    final isArabic =
        AppLocalizations.of(context).locale.languageCode == 'ar';

    final name = isArabic ? store.nameAr : store.nameEn;

    final category = isArabic
        ? (store.mainCategoryNameAr ?? store.mainCategoryNameEn)
        : (store.mainCategoryNameEn ?? store.mainCategoryNameAr);

    final categoryName = category?.trim() ?? '';

    final cuisines = store.cuisines
        .map((cuisine) => cuisine.localizedName(isArabic)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    final isClosed = store.isOpenNow == false;

    final coverHeight = featured ? 128.0 : 108.0;
    final iconUrl = store.iconUrl?.trim();
    final showLogo = iconUrl != null && iconUrl.isNotEmpty;

    final logoSize = featured ? 84.0 : 76.0;
    final overlap = showLogo ? logoSize / 2 : 0.0;

    final radius = BorderRadius.circular(featured ? 20 : 16);
    final pad = featured ? AppSpacing.md : AppSpacing.sm;

    return Material(
      color: colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: colors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (featured)
              ColoredBox(
                color: colors.primary,
                child: const SizedBox(height: 4),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _RestaurantCover(
                  store: store,
                  height: coverHeight,
                ),

                // Dark overlay for closed restaurants.
                if (isClosed)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: .32),
                      ),
                    ),
                  ),

                // Offer badge appears only for stores with active offers.
                if (hasActiveOffers)
                  PositionedDirectional(
                    top: AppSpacing.xs,
                    start: AppSpacing.xs,
                    child: _OfferPill(
                      isArabic: isArabic,
                    ),
                  ),

                // Open/closed status.
                if (store.isOpenNow != null)
                  PositionedDirectional(
                    top: AppSpacing.xs,
                    end: AppSpacing.xs,
                    child: _StoreStatusPill(
                      isOpenNow: store.isOpenNow!,
                    ),
                  ),

                // Store logo overlaps the bottom edge of the cover.
                if (showLogo)
                  PositionedDirectional(
                    start: pad,
                    top: coverHeight - overlap,
                    child: _RestaurantLogo(
                      store: store,
                      size: logoSize,
                      radius: featured ? 20 : 18,
                    ),
                  ),
              ],
            ),

            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                pad,
                overlap + AppSpacing.xs,
                pad,
                pad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: featured ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: (featured
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleSmall)
                              ?.copyWith(
                            color: colors.headingText,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (featured) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: homeAccent(context),
                        ),
                      ],
                    ],
                  ),

                  // Main category.
                  if (categoryName.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  // Cuisine names as separate pills.
                  if (cuisines.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final cuisine in cuisines.take(3))
                          _CuisinePill(label: cuisine),
                      ],
                    ),
                  ],

                  // Rating, delivery time, and delivery fee.
                  _RestaurantFacts(store: store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uses images[0] as cover.
/// If no uploaded cover exists, displays the Luqma brand placeholder.
/// The logo remains separate and is never used as a cover.
class _RestaurantCover extends StatelessWidget {
  const _RestaurantCover({
    required this.store,
    required this.height,
  });

  final Store store;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: store.hasUploadedCover
          ? AppNetworkImage(
        url: store.coverImageUrl,
        fit: BoxFit.cover,
        placeholder: _BrandCover(height: height),
      )
          : _BrandCover(height: height),
    );
  }
}

/// Brand-colored fallback cover.
class _BrandCover extends StatelessWidget {
  const _BrandCover({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    final gradient = <Color>[
      colors.primary,
      Color.lerp(colors.primary, Colors.black, .38)!,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -height * .25,
            top: -height * .35,
            child: _disc(
              colors.accent,
              height * 1.1,
              .14,
            ),
          ),
          PositionedDirectional(
            start: -height * .2,
            bottom: -height * .5,
            child: _disc(
              colors.accent,
              height * .9,
              .10,
            ),
          ),
          Center(
            child: ExcludeSemantics(
              child: Icon(
                Icons.restaurant_rounded,
                size: height * .34,
                color: colors.accent.withValues(alpha: .4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _disc(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}

/// Offer badge.
class _OfferPill extends StatelessWidget {
  const _OfferPill({
    required this.isArabic,
  });

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadius.pillRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              color: Colors.white,
              size: 13,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              isArabic ? 'عروض متاحة' : 'Offers available',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuisine category pill.
class _CuisinePill extends StatelessWidget {
  const _CuisinePill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.iconSurface,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: colors.border.withValues(alpha: .65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Open/closed status pill.
class _StoreStatusPill extends StatelessWidget {
  const _StoreStatusPill({
    required this.isOpenNow,
  });

  final bool isOpenNow;

  static const Color _openGreen = Color(0xFF2E7D4F);
  static const Color _closedBackground = Color(0xFF393431);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context).catalog;

    final background = isOpenNow
        ? Colors.white.withValues(alpha: .96)
        : _closedBackground;

    final foreground = isOpenNow ? _openGreen : Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                isOpenNow
                    ? Icons.circle
                    : Icons.schedule_rounded,
                size: isOpenNow ? 8 : 12,
                color: foreground,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              isOpenNow ? l10n.open : l10n.closed,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Store profile logo.
class _RestaurantLogo extends StatelessWidget {
  const _RestaurantLogo({
    required this.store,
    required this.size,
    required this.radius,
  });

  final Store store;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2),
        child: AppNetworkImage(
          url: store.iconUrl,
          fit: BoxFit.cover,
          placeholder: const StoreArtworkPlaceholder(),
        ),
      ),
    );
  }
}

/// Displays only the agreed card facts:
/// 1. Rating and ratings count.
/// 2. Delivery time.
/// 3. Delivery fee.
///
/// Missing or zero values are omitted.
class _RestaurantFacts extends StatelessWidget {
  const _RestaurantFacts({
    required this.store,
  });

  final Store store;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    final copy = AppLocalizations.of(context).catalog;

    final rating = store.averageRating;
    final ratingsCount = store.ratingsCount;

    final hasRating = rating != null &&
        rating.isFinite &&
        rating > 0 &&
        rating <= 5 &&
        ratingsCount != null &&
        ratingsCount > 0;

    final minutes = store.deliveryTimeMinutes;
    final hasMinutes = minutes != null && minutes > 0;

    final fee = store.deliveryFee;
    final hasFee = fee != null && fee.isFinite && fee > 0;

    final chips = <Widget>[
      if (hasRating)
        _FactChip(
          icon: Icons.star_rounded,
          label: '${copy.number(double.parse(rating.toStringAsFixed(1)))}'
              ' (${copy.number(ratingsCount)})',
          iconColor: const Color(0xFFE5A52B),
          tint: const Color(0xFFE5A52B),
        ),
      if (hasMinutes)
        _FactChip(
          icon: Icons.schedule_rounded,
          label: copy.deliveryMinutes(minutes),
          iconColor: colors.primary,
          tint: colors.primary,
        ),
      if (hasFee)
        _FactChip(
          icon: Icons.delivery_dining_rounded,
          label: copy.deliveryFee(fee),
          iconColor: colors.primary,
          tint: colors.primary,
        ),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: chips,
      ),
    );
  }
}

/// Reusable fact chip.
class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .08),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: 14,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.bodyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
