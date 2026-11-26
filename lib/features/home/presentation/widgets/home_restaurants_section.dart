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
        const gap = AppSpacing.sm;
        final smallWidth = (constraints.maxWidth - gap) / 2;
        return Column(
          key: const Key('home_restaurants_results'),
          children: [
            _RestaurantCard(
              store: restaurants.first,
              featured: true,
              onTap:
                  onStoreTap == null ? null : () => onStoreTap!(restaurants.first),
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
                      child: _RestaurantCard(
                        store: store,
                        featured: false,
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

/// One card for both layouts.
///
/// The card keeps its established shape — cover on top, logo badge, name,
/// category, quick facts — and changes only where the data comes from: the
/// cover is `images[0]` (falling back to the logo, then a placeholder), never a
/// later gallery photo, and every zero-valued API field is omitted instead of
/// rendered.
class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.store,
    required this.featured,
    this.onTap,
  });

  final Store store;
  final bool featured;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isArabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final name = isArabic ? store.nameAr : store.nameEn;
    final category = isArabic
        ? (store.mainCategoryNameAr ?? store.mainCategoryNameEn)
        : (store.mainCategoryNameEn ?? store.mainCategoryNameAr);
    final address = store.address?.trim();

    final coverHeight = featured ? 112.0 : 84.0;
    // The logo badge only adds information when the cover is a photo that is
    // not the logo itself. The real Store payload repeats `iconUrl` inside
    // `images`, so a plain `hasUploadedCover` check would draw it twice.
    final iconUrl = store.iconUrl?.trim();
    final showLogo = store.hasUploadedCover &&
        iconUrl != null &&
        iconUrl.isNotEmpty &&
        iconUrl != store.coverImageUrl;
    final logoSize = featured ? 56.0 : 44.0;
    final overlap = showLogo ? logoSize / 2 : 0.0;
    final radius = BorderRadius.circular(featured ? 20 : 16);
    final pad = featured ? AppSpacing.md : AppSpacing.sm;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: colors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _RestaurantCover(store: store, height: coverHeight),
                if (store.isOpenNow != null)
                  PositionedDirectional(
                    top: AppSpacing.xs,
                    end: AppSpacing.xs,
                    child: _StoreStatusPill(isOpenNow: store.isOpenNow!),
                  ),
                if (showLogo)
                  PositionedDirectional(
                    start: pad,
                    top: coverHeight - overlap,
                    child: _RestaurantLogo(
                      store: store,
                      size: logoSize,
                      radius: featured ? 16 : 12,
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
                          isRtl
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                          color: colors.link,
                        ),
                      ],
                    ],
                  ),
                  if (category?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      category!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.mutedText),
                    ),
                  ],
                  if (featured && address != null && address.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 14, color: colors.mutedText),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.mutedText),
                          ),
                        ),
                      ],
                    ),
                  ],
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

/// `images[0]` cover photo, with the logo then the Luqma placeholder as
/// fallbacks (`Store.coverImageUrl` owns that priority). The box keeps its
/// height in every state — including a failed load — so nothing shifts.
class _RestaurantCover extends StatelessWidget {
  const _RestaurantCover({required this.store, required this.height});

  final Store store;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: AppNetworkImage(
        url: store.coverImageUrl,
        fit: BoxFit.cover,
        placeholder: const StoreArtworkPlaceholder(),
      ),
    );
  }
}

class _StoreStatusPill extends StatelessWidget {
  const _StoreStatusPill({required this.isOpenNow});

  final bool isOpenNow;

  static const Color _openGreen = Color(0xFF2E7D4F);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context).catalog;
    final color = isOpenNow ? _openGreen : const Color(0xFF6B5F59);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
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
                isOpenNow ? Icons.circle : Icons.schedule_rounded,
                size: isOpenNow ? 8 : 12,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              isOpenNow ? l10n.open : l10n.closed,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        border: Border.all(color: colors.border),
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

/// Quick facts, each rendered only when the API supplies a usable value.
class _RestaurantFacts extends StatelessWidget {
  const _RestaurantFacts({required this.store});

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

    final distance = store.distanceKm;
    final hasDistance =
        distance != null && distance.isFinite && distance > 0 && store.hasUsableCoordinates;

    final priceLevel = store.priceLevel?.trim();
    final hasPriceLevel = priceLevel != null && priceLevel.isNotEmpty;

    final hours = copy.openingWindow(store.openTime, store.closeTime);
    final opensAt = store.isOpenNow == false ? copy.opensAt(store.openTime) : null;

    final chips = <Widget>[
      if (hasRating)
        _FactChip(
          icon: Icons.star_rounded,
          label: copy.number(double.parse(rating.toStringAsFixed(1))),
          iconColor: colors.accent,
          tint: colors.accent,
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
      if (hasDistance)
        _FactChip(
          icon: Icons.near_me_outlined,
          label: copy.distanceKm(distance),
          iconColor: colors.primary,
          tint: colors.primary,
        ),
      if (hasPriceLevel)
        _FactChip(
          icon: Icons.payments_outlined,
          label: priceLevel,
          iconColor: colors.primary,
          tint: colors.primary,
        ),
      if (hours != null)
        _FactChip(
          icon: Icons.schedule_outlined,
          label: hours,
          iconColor: colors.mutedText,
          tint: colors.mutedText,
        )
      else if (opensAt != null)
        _FactChip(
          icon: Icons.schedule_outlined,
          label: opensAt,
          iconColor: colors.mutedText,
          tint: colors.mutedText,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: chips,
      ),
    );
  }
}

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
            ExcludeSemantics(child: Icon(icon, size: 14, color: iconColor)),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.bodyText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}