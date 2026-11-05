import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/restaurant_summary.dart';
import 'home_section.dart';

/// Restaurant grid — modern premium cards with clear hierarchy:
/// image → name → price/details, using Luqma theme and responsive spacing.
class HomeRestaurantsSection extends StatelessWidget {
  const HomeRestaurantsSection({required this.restaurants, super.key});

  static const double _cardMaxWidth = 260;
  static const double _cardHeight = 220;

  final List<RestaurantSummary> restaurants;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return HomeSection(
      title: l10n.home.restaurantsTitle,
      child: restaurants.isEmpty
          ? HomeSectionPlaceholder(
              icon: Icons.restaurant_outlined,
              message: l10n.home.restaurantsEmpty,
            )
          : GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: _cardMaxWidth,
                mainAxisExtent: _cardHeight,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: restaurants.length,
              itemBuilder: (context, index) =>
                  _RestaurantCard(restaurant: restaurants[index]),
            ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant});

  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final theme = Theme.of(context);

    return Card(
      key: Key('restaurant_card_${restaurant.id}'),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mediumRadius,
        side: BorderSide(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _RestaurantImage(restaurant: restaurant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.headingText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the artwork the API supplies when there is one and a neutral
/// placeholder otherwise, so the section never renders a broken image.
class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({required this.restaurant});

  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context) {
    final imageUrl = restaurant.imageUrl?.trim() ?? '';
    if (imageUrl.isEmpty) {
      return const _RestaurantImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _RestaurantImagePlaceholder(),
      errorBuilder: (context, error, stackTrace) =>
          const _RestaurantImagePlaceholder(),
    );
  }
}

class _RestaurantImagePlaceholder extends StatelessWidget {
  const _RestaurantImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return ColoredBox(
      color: colors.elevatedSurface,
      child: Center(
        child: Icon(
          Icons.restaurant_outlined,
          size: AppSizes.iconLarge,
          color: colors.mutedText,
        ),
      ),
    );
  }
}
