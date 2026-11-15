import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_circle_icon_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/store.dart';
import 'store_card.dart';
import 'store_status_badge.dart';

/// Hero photo with floating actions and an info card that overlaps it.
///
/// No clock, API calls or fabricated metadata: it renders the passed GET
/// snapshot (name, category, live status, phone, address). Favourite and share
/// are visual only until their backends exist.
class StoreDetailsHeader extends StatelessWidget {
  const StoreDetailsHeader({
    required this.store,
    required this.onFavorite,
    required this.onShare,
    super.key,
  });

  static const double _heroHeight = 280;
  static const double _overlap = 44;

  final Store store;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final copy = AppLocalizations.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final overlayBackground = colors.surface.withValues(alpha: .92);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _heroHeight,
          child: Stack(fit: StackFit.expand, children: [
            AppNetworkImage(
              url: store.iconUrl,
              placeholder: const StoreArtworkPlaceholder(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x73000000), Color(0x00000000)],
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, _heroHeight - _overlap, AppSpacing.md, 0),
          child: _StoreInfoCard(store: store),
        ),
        PositionedDirectional(
          top: top + AppSpacing.xs,
          start: AppSpacing.md,
          child: AppCircleIconButton(
            key: const Key('store_back'),
            icon: Icons.arrow_back_rounded,
            tooltip: copy.common.back,
            backgroundColor: overlayBackground,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        PositionedDirectional(
          top: top + AppSpacing.xs,
          end: AppSpacing.md,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AppCircleIconButton(
              key: const Key('store_share'),
              icon: Icons.share_outlined,
              tooltip: copy.catalog.share,
              backgroundColor: overlayBackground,
              onPressed: onShare,
            ),
            const SizedBox(width: AppSpacing.xs),
            AppCircleIconButton(
              key: const Key('store_favorite'),
              icon: Icons.favorite_border_rounded,
              tooltip: copy.catalog.favorite,
              backgroundColor: overlayBackground,
              iconColor: colors.primary,
              onPressed: onFavorite,
            ),
          ]),
        ),
      ],
    );
  }
}

class _StoreInfoCard extends StatelessWidget {
  const _StoreInfoCard({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context);
    final copy = l10n.catalog;
    final arabic = l10n.locale.languageCode == 'ar';
    final categoryName =
        arabic ? store.mainCategoryNameAr : store.mainCategoryNameEn;
    final hasPhone = store.phoneNumber?.isNotEmpty == true;
    final hasAddress = store.address?.isNotEmpty == true;
    final hasHours = store.openingHours?.isNotEmpty == true;

    // Only facts the API actually returned; each one is optional.
    final meta = <Widget>[
      if (store.distanceKm != null)
        _MetaItem(
            icon: Icons.place_rounded,
            iconColor: colors.primary,
            text: copy.distanceKm(store.distanceKm!)),
      if (store.rating != null)
        _MetaItem(
          icon: Icons.star_rounded,
          iconColor: colors.accent,
          text: copy.number(double.parse(store.rating!.toStringAsFixed(1))),
          strong: true,
          trailing: store.ratingCount == null
              ? null
              : copy.ratingCount(store.ratingCount!),
        ),
      if (store.priceFrom != null || store.priceTo != null)
        _MetaItem(
          text: copy.priceBand(store.priceFrom ?? store.priceTo!,
              store.priceTo ?? store.priceFrom!),
        ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: theme.brightness == Brightness.dark ? .35 : .08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                arabic ? store.nameAr : store.nameEn,
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.headingText, fontWeight: FontWeight.w800),
              ),
            ),
            if (categoryName?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(categoryName!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.mutedText)),
            ],
            if (meta.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: meta,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              StoreStatusBadge(isOpenNow: store.isOpenNow),
              if (hasHours) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(store.openingHours!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.mutedText)),
                ),
              ],
            ]),
            if (hasPhone) ...[
              const SizedBox(height: AppSpacing.md),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Icon(Icons.phone_outlined, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(store.phoneNumber!,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyMedium),
                ),
              ]),
            ],
            if (hasAddress) ...[
              const SizedBox(height: AppSpacing.md),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.storefront_outlined, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(store.address!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.mutedText)),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.text,
    this.icon,
    this.iconColor,
    this.trailing,
    this.strong = false,
  });

  final String text;
  final IconData? icon;
  final Color? iconColor;
  final String? trailing;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
      ],
      Text(text,
          style: theme.textTheme.labelLarge?.copyWith(
              color: colors.bodyText,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
      if (trailing != null) ...[
        const SizedBox(width: 4),
        Text(trailing!,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: colors.mutedText)),
      ],
    ]);
  }
}
