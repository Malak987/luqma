import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/translations/catalog_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/store.dart';
import '../utils/store_location.dart';
import 'store_status_badge.dart';

/// A compact, data-driven Store/GetAll card used by Home and discovery.
///
/// Every optional element is omitted instead of being estimated. The optional
/// [promotionBadge] is a presentation slot for a future *real* store promotion
/// response; the current Store API does not supply one.
class StoreCard extends StatelessWidget {
  const StoreCard({
    required this.store,
    required this.onTap,
    this.locationLauncher = launchStoreLocation,
    this.promotionBadge,
    super.key,
  });

  final Store store;
  final VoidCallback onTap;
  final StoreLocationLauncher locationLauncher;
  final Widget? promotionBadge;

  static const List<double> _grayscale = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final name = arabic ? store.nameAr : store.nameEn;
    final categoryName = arabic
        ? store.mainCategoryNameAr ?? store.mainCategoryNameEn
        : store.mainCategoryNameEn ?? store.mainCategoryNameAr;
    final description = _localizedText(
      arabic ? store.descriptionAr : store.descriptionEn,
      arabic ? store.descriptionEn : store.descriptionAr,
    );
    final cuisineNames = store.cuisines
        .map((cuisine) => cuisine.localizedName(arabic))
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final locationUri = StoreLocation.googleMapsUri(
      latitude: store.latitude,
      longitude: store.longitude,
      address: store.address,
    );
    final metadata = _metadata(copy, colors);

    Widget artwork = AppNetworkImage(
      url: store.iconUrl,
      placeholder: const StoreArtworkPlaceholder(),
    );
    if (store.isOpenNow == false) {
      artwork = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscale),
        child: artwork,
      );
    }

    return Semantics(
      container: true,
      button: true,
      label: name,
      child: Material(
        color: colors.surface,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: .12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    artwork,
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: <Color>[
                            Color(0x66000000),
                            Color(0x00000000),
                          ],
                        ),
                      ),
                    ),
                    if (store.isOpenNow != null)
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        start: AppSpacing.sm,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: .94),
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: StoreStatusBadge(isOpenNow: store.isOpenNow!),
                        ),
                      ),
                    if (promotionBadge != null)
                      PositionedDirectional(
                        top: AppSpacing.sm,
                        end: AppSpacing.sm,
                        child: promotionBadge!,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.bodyText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ExcludeSemantics(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(
                              dimension: 32,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: AppSizes.iconSmall,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (categoryName?.isNotEmpty == true) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        categoryName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: colors.primary),
                      ),
                    ],
                    if (cuisineNames.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        cuisineNames.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.mutedText),
                      ),
                    ],
                    if (metadata.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: metadata,
                      ),
                    ],
                    if (description != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        key: const Key('store_description'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.mutedText, height: 1.35),
                      ),
                    ],
                    if (locationUri != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          key: const Key('store_location_action'),
                          onPressed: () => _openLocation(context, locationUri),
                          icon: const Icon(Icons.location_on_outlined,
                              size: AppSizes.iconSmall),
                          label: Text(
                            store.address?.trim().isNotEmpty == true
                                ? '${copy.openLocation} · ${store.address!.trim()}'
                                : copy.openLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _metadata(
    CatalogTranslations copy,
    AppSemanticColors colors,
  ) {
    final rating = store.averageRating;
    final ratingsCount = store.ratingsCount;
    final hasRating = rating != null &&
        rating.isFinite &&
        rating >= 0 &&
        rating <= 5 &&
        ratingsCount != null &&
        ratingsCount > 0;
    final distance = store.distanceKm;
    final hasDistance = distance != null && distance >= 0;
    final deliveryTime = store.deliveryTimeMinutes;
    final hasDeliveryTime = deliveryTime != null && deliveryTime > 0;
    final deliveryFee = store.deliveryFee;
    final hasDeliveryFee = deliveryFee != null && deliveryFee >= 0;
    final priceLevel = store.priceLevel?.trim();

    return <Widget>[
      if (hasRating)
        _StoreMetaItem(
          icon: Icons.star_rounded,
          iconColor: colors.accent,
          text: copy.number(double.parse(rating!.toStringAsFixed(1))),
          semanticsLabel: copy.ratingWithCount(rating!, ratingsCount!),
          trailing: copy.ratingCount(ratingsCount!),
          strong: true,
        ),
      if (hasDistance)
        _StoreMetaItem(
          icon: Icons.near_me_outlined,
          iconColor: colors.primary,
          text: copy.distanceKm(distance!),
          semanticsLabel: copy.distanceKm(distance!),
        ),
      if (hasDeliveryTime)
        _StoreMetaItem(
          icon: Icons.timer_outlined,
          iconColor: colors.primary,
          text: copy.deliveryMinutes(deliveryTime!),
          semanticsLabel: copy.deliveryMinutes(deliveryTime!),
        ),
      if (hasDeliveryFee)
        _StoreMetaItem(
          icon: Icons.delivery_dining_outlined,
          iconColor: colors.primary,
          text: copy.deliveryFee(deliveryFee!),
          semanticsLabel: copy.deliveryFee(deliveryFee!),
        ),
      if (priceLevel != null && priceLevel.isNotEmpty)
        _StoreMetaItem(
          icon: Icons.payments_outlined,
          iconColor: colors.primary,
          text: priceLevel,
          semanticsLabel: copy.priceLevelValue(priceLevel),
        ),
    ];
  }

  Future<void> _openLocation(BuildContext context, Uri uri) async {
    try {
      final launched = await locationLauncher(uri);
      if (!launched && context.mounted) _showLocationFailure(context);
    } catch (_) {
      if (context.mounted) _showLocationFailure(context);
    }
  }

  void _showLocationFailure(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).catalog.locationOpenFailed),
        ),
      );
  }

  String? _localizedText(String? preferred, String? fallback) {
    final preferredValue = preferred?.trim();
    if (preferredValue?.isNotEmpty == true) return preferredValue;
    final fallbackValue = fallback?.trim();
    return fallbackValue?.isNotEmpty == true ? fallbackValue : null;
  }
}

class _StoreMetaItem extends StatelessWidget {
  const _StoreMetaItem({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.semanticsLabel,
    this.trailing,
    this.strong = false,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final String semanticsLabel;
  final String? trailing;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: AppSizes.iconSmall, color: iconColor),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.bodyText,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xxs),
              Text(
                trailing!,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: colors.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StoreArtworkPlaceholder extends StatelessWidget {
  const StoreArtworkPlaceholder({super.key});

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
