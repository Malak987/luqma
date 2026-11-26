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

/// One card for both layouts: a burgundy banner, the logo overlapping its
/// lower edge, then name, location and quick facts (rating, time, fee).
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

    final bannerHeight = featured ? 92.0 : 64.0;
    final logoSize = featured ? 72.0 : 54.0;
    final overlap = logoSize / 2;
    final radius = BorderRadius.circular(featured ? 24 : 20);
    final pad = featured ? AppSpacing.md : AppSpacing.sm;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: colors.surface,
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
                  _RestaurantBanner(height: bannerHeight, colors: colors),
                  if (store.isOpenNow != null)
                    PositionedDirectional(
                      top: AppSpacing.xs,
                      end: AppSpacing.xs,
                      child: _OpenPill(isOpen: store.isOpenNow!),
                    ),
                  PositionedDirectional(
                    start: pad,
                    top: bannerHeight - overlap,
                    child: _RestaurantLogo(
                      store: store,
                      size: logoSize,
                      radius: featured ? 20 : 16,
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
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: .08),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                isRtl
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                                color: colors.link,
                              ),
                            ),
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
      ),
    );
  }
}

class _RestaurantBanner extends StatelessWidget {
  const _RestaurantBanner({required this.height, required this.colors});

  final double height;
  final AppSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              colors.primary,
              Color.lerp(colors.primary, Colors.black, .30)!,
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            PositionedDirectional(
              top: -height * .55,
              end: -height * .20,
              child: _Blob(size: height * 1.3, color: colors.accent, alpha: .22),
            ),
            PositionedDirectional(
              bottom: -height * .50,
              start: height * .60,
              child: _Blob(size: height * 1.0, color: Colors.white, alpha: .06),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color, required this.alpha});

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: alpha),
          ),
          child: SizedBox(width: size, height: size),
        ),
      );
}

class _OpenPill extends StatelessWidget {
  const _OpenPill({required this.isOpen});

  final bool isOpen;

  static const Color _openGreen = Color(0xFF2E7D4F);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context).catalog;
    final color = isOpen ? _openGreen : const Color(0xFF6B5F59);
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
                isOpen ? Icons.circle : Icons.schedule_rounded,
                size: isOpen ? 8 : 12,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              isOpen ? l10n.open : l10n.closed,
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
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(radius),
        // Surface-coloured ring so the logo reads as cut out of the banner.
        border: Border.all(color: colors.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AppNetworkImage(
        url: store.iconUrl,
        fit: BoxFit.contain,
        placeholder: const StoreArtworkPlaceholder(),
      ),
    );
  }
}

class _RestaurantFacts extends StatelessWidget {
  const _RestaurantFacts({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    final rating = store.averageRating;
    final hasRating = rating != null &&
        rating.isFinite &&
        rating >= 0 &&
        rating <= 5 &&
        (store.ratingsCount ?? 0) > 0;
    final minutes = store.deliveryTimeMinutes;
    final fee = store.deliveryFee;

    final chips = <Widget>[
      if (hasRating)
        _FactChip(
          icon: Icons.star_rounded,
          label: copy.number(double.parse(rating.toStringAsFixed(1))),
          iconColor: colors.accent,
          tint: colors.accent,
          emphasised: true,
        ),
      if (minutes != null && minutes > 0)
        _FactChip(
          icon: Icons.schedule_rounded,
          label: copy.deliveryMinutes(minutes),
          iconColor: colors.primary,
          tint: colors.primary,
        ),
      if (fee != null && fee >= 0)
        _FactChip(
          icon: Icons.delivery_dining_rounded,
          label: copy.deliveryFee(fee),
          iconColor: colors.primary,
          tint: colors.primary,
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
    this.emphasised = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color tint;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: emphasised ? .18 : .08),
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
