import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/restaurant_summary.dart';
import 'home_section.dart';

class HomeRestaurantsSection extends StatelessWidget {
  const HomeRestaurantsSection({
    required this.restaurants,
    this.onSeeAll,
    super.key,
  });

  static const double _cardWidth = 172;
  static const double _listHeight = 236;

  final List<RestaurantSummary> restaurants;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).home;

    return HomeSection(
      title: l10n.restaurantsTitle,        // "الأكثر طلباً هذا الأسبوع"
      subtitle: l10n.restaurantsSubtitle,  // "أطباق مميزة ومفضلة لدى الجميع"
      seeAllLabel: l10n.seeAll,
      onSeeAll: onSeeAll,
      child: restaurants.isEmpty
          ? HomeSectionPlaceholder(
        icon: Icons.restaurant_outlined,
        message: l10n.restaurantsEmpty,
      )
          : SizedBox(
        height: _listHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: restaurants.length,
          separatorBuilder: (_, __) =>
          const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, i) => SizedBox(
            width: _cardWidth,
            child: _RestaurantCard(restaurant: restaurants[i]),
          ),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant});
  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Container(
      key: Key('restaurant_card_${restaurant.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _RestaurantImage(restaurant: restaurant),
                  if (restaurant.badge != null)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: const BorderRadiusDirectional.only(
                            bottomStart: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          restaurant.badge!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (restaurant.rating != null) ...[
                Icon(Icons.star_rounded, size: 14, color: colors.accent),
                const SizedBox(width: 2),
                Text(
                  restaurant.rating!.toStringAsFixed(1),
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.accent, fontWeight: FontWeight.w700),
                ),
              ],
              const Spacer(),
              if (restaurant.deliveryTime != null)
                Text(
                  restaurant.deliveryTime!,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: colors.mutedText, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            restaurant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
                color: colors.headingText, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({required this.restaurant});
  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context) {
    final url = restaurant.imageUrl?.trim() ?? '';
    if (url.isEmpty) return const _Placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      loadingBuilder: (_, child, p) => p == null ? child : const _Placeholder(),
      errorBuilder: (_, __, ___) => const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return ColoredBox(
      color: colors.elevatedSurface,
      child: Center(
        child: Icon(Icons.restaurant_outlined,
            size: AppSizes.iconLarge, color: colors.mutedText),
      ),
    );
  }
}