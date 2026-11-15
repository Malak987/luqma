import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/menu_item.dart';

/// One menu row: photo, name, description, price and the add control.
///
/// Uses only the real GET snapshot. A sale badge appears only when the item
/// really has a higher compare-at price; no percentage is derived, and ratings,
/// dietary tags and currency are not manufactured.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    required this.item,
    required this.onTap,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.quantity = 0,
    super.key,
  });

  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// Units of this exact item already in the cart (0 shows the add button).
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final name = arabic ? item.nameAr : item.nameEn;
    final description = arabic ? item.descriptionAr : item.descriptionEn;

    final artwork = ClipRRect(
      borderRadius: AppRadius.largeRadius,
      child: Stack(fit: StackFit.expand, children: [
        AppNetworkImage(
            url: item.imageUrl, placeholder: const MenuArtworkPlaceholder()),
        if (item.hasSale)
          PositionedDirectional(
            top: AppSpacing.xs,
            start: AppSpacing.xs,
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: colors.primary, borderRadius: AppRadius.smallRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                child: Text(copy.discountPercent(item.discountPercent),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
    );

    final control = _AddControl(
      itemId: item.id,
      quantity: quantity,
      onAdd: onAdd,
      onIncrement: onIncrement,
      onDecrement: onDecrement,
    );

    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
              color: colors.bodyText, fontWeight: FontWeight.w800)),
      if (description.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xxs),
        Text(description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                theme.textTheme.bodySmall?.copyWith(color: colors.mutedText)),
      ],
      if (item.isSoldByWeight || item.weight != null) ...[
        const SizedBox(height: AppSpacing.xxs),
        MenuItemWeight(item: item),
      ],
      const SizedBox(height: AppSpacing.sm),
      Row(children: [
        Expanded(
            child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: MenuItemPrice(item: item, showSaleBadge: false))),
        const SizedBox(width: AppSpacing.xs),
        control,
      ]),
    ]);

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlargeRadius,
          side: BorderSide(color: colors.border)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < AppSizes.compactWidth - AppSpacing.xl ||
                MediaQuery.textScalerOf(context).scale(1) > 1.35) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(aspectRatio: 2, child: artwork),
                    const SizedBox(height: AppSpacing.sm),
                    content,
                  ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox.square(dimension: 104, child: artwork),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: content),
            ]);
          }),
        ),
      ),
    );
  }
}

class _AddControl extends StatelessWidget {
  const _AddControl({
    required this.itemId,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String itemId;
  final int quantity;
  final VoidCallback? onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context);
    final copy = l10n.catalog;

    if (quantity <= 0) {
      return OutlinedButton(
        key: ValueKey('menu_add_${itemId.toLowerCase()}'),
        style: OutlinedButton.styleFrom(
          // The app theme makes outlined buttons full width; opt out here.
          minimumSize: const Size(72, 36),
          maximumSize: const Size(double.infinity, 36),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        onPressed: onAdd,
        child: Text(copy.add),
      );
    }

    return DecoratedBox(
      key: ValueKey('menu_stepper_${itemId.toLowerCase()}'),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: colors.primary),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: l10n.cart.decrease,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.remove_rounded, size: 18, color: colors.primary),
          onPressed: onDecrement,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 20),
          child: Text(copy.number(quantity),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
        ),
        IconButton(
          tooltip: l10n.cart.increase,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.add_rounded, size: 18, color: colors.primary),
          onPressed: onIncrement,
        ),
      ]),
    );
  }
}

/// Shared by the card and product sheet; no rounding, currency or derived
/// discount percentage is assumed. A crossed-out price requires a real sale.
class MenuItemPrice extends StatelessWidget {
  const MenuItemPrice({required this.item, this.showSaleBadge = true, super.key});
  final MenuItem item;

  /// The card shows its own badge on the photo, so it turns this off.
  final bool showSaleBadge;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).catalog;
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xxs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(copy.money(item.price),
              semanticsLabel: '${copy.price}: ${copy.money(item.price)}',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? colors.bodyText
                      : colors.headingText,
                  fontWeight: FontWeight.w800)),
          if (item.hasSale) ...[
            Text(copy.money(item.compareAtPrice),
                semanticsLabel:
                    '${copy.previousPrice}: ${copy.money(item.compareAtPrice)}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                    decoration: TextDecoration.lineThrough)),
            if (showSaleBadge)
              DecoratedBox(
                decoration: BoxDecoration(
                    color: colors.primary, borderRadius: AppRadius.smallRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  child: Text(copy.sale,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: colors.onPrimary)),
                ),
              ),
          ],
        ]);
  }
}

class MenuItemWeight extends StatelessWidget {
  const MenuItemWeight({required this.item, super.key});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).catalog;
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xxs, children: [
      if (item.isSoldByWeight)
        Text(copy.soldByWeight, style: Theme.of(context).textTheme.bodySmall),
      if (item.weight != null)
        Text('${copy.weight}: ${copy.number(item.weight!)}',
            style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class MenuArtworkPlaceholder extends StatelessWidget {
  const MenuArtworkPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return ColoredBox(
        color: colors.elevatedSurface,
        child: Center(
            child: Icon(Icons.restaurant_menu,
                color: colors.mutedText, size: AppSizes.iconLarge)));
  }
}
