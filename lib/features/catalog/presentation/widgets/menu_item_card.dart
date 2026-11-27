import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/menu_item.dart';
import 'shared_product_card.dart';

/// One menu row: photo, name, description, price and the add control.
///
/// Uses the GET snapshot without inferring active promotions from prices.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    required this.item,
    required this.onTap,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.quantity = 0,
    this.isAdding = false,
    this.readOnlyLine = false,
    super.key,
  });

  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  /// Units of this exact item already in the cart (0 shows the add button).
  final int quantity;
  final bool isAdding;
  final bool readOnlyLine;

  @override
  Widget build(BuildContext context) {
    final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    return SharedProductCard(
      id: item.id,
      name: arabic ? item.nameAr : item.nameEn,
      description: arabic ? item.descriptionAr : item.descriptionEn,
      imageUrl: item.imageUrl,
      placeholder: const MenuArtworkPlaceholder(),
      price: MenuItemPrice(item: item, showSaleBadge: false),
      metadata: item.isSoldByWeight || item.weight != null
          ? MenuItemWeight(item: item)
          : null,
      action: _AddControl(
          itemId: item.id,
          quantity: quantity,
          isAdding: isAdding,
          readOnlyLine: readOnlyLine,
          onAdd: onAdd,
          onIncrement: onIncrement,
          onDecrement: onDecrement),
      onTap: onTap,
    );
  }
}

class _AddControl extends StatelessWidget {
  const _AddControl({
    required this.itemId,
    required this.quantity,
    required this.isAdding,
    required this.readOnlyLine,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String itemId;
  final int quantity;
  final bool isAdding;
  final bool readOnlyLine;
  final VoidCallback? onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context);
    final copy = l10n.catalog;
    final actionColor =
        theme.brightness == Brightness.dark ? colors.link : colors.primary;

    final reduceMotion = MediaQuery.of(context).disableAnimations ||
        MediaQuery.of(context).accessibleNavigation;
    final Widget action;
    if (quantity > 0 && readOnlyLine) {
      action = Text(
        l10n.cart.itemsInCart(quantity),
        key: ValueKey('menu_readonly_${itemId.toLowerCase()}'),
        style: theme.textTheme.labelMedium?.copyWith(color: colors.mutedText),
      );
    } else if (quantity <= 0) {
      action = FilledButton(
        key: ValueKey('menu_add_${itemId.toLowerCase()}'),
        style: FilledButton.styleFrom(
          // Keep the action compact while retaining a full touch target.
          minimumSize: const Size(72, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        onPressed: onAdd,
        child: isAdding
            ? Semantics(
                label: copy.add,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                    semanticsLabel: l10n.cart.loading,
                  ),
                ),
              )
            : Text(copy.add),
      );
    } else {
      action = DecoratedBox(
        key: ValueKey('menu_stepper_${itemId.toLowerCase()}'),
        decoration: BoxDecoration(
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: actionColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: quantity > 1 ? l10n.cart.decrease : l10n.cart.remove,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              color: actionColor,
              icon: const Icon(Icons.remove_rounded, size: 20),
              onPressed: onDecrement,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                copy.number(quantity),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: actionColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.cart.increase,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              color: actionColor,
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: onIncrement,
            ),
          ],
        ),
      );
    }
    return AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => IgnorePointer(
        ignoring: child.key != action.key,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: action,
    );
  }
}

/// Shared by the card and product sheet; no rounding, currency or derived
/// discount percentage or active offer is inferred from compare-at prices.
class MenuItemPrice extends StatelessWidget {
  const MenuItemPrice({
    required this.item,
    this.showSaleBadge = true,
    super.key,
  });
  final MenuItem item;

  /// Retained for existing callers; promotion badges require a verified contract.
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
        Text(
          copy.money(item.price),
          semanticsLabel: '${copy.price}: ${copy.money(item.price)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.brightness == Brightness.dark
                ? colors.bodyText
                : colors.headingText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class MenuItemWeight extends StatelessWidget {
  const MenuItemWeight({required this.item, super.key});
  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).catalog;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xxs,
      children: [
        if (item.isSoldByWeight)
          Text(copy.soldByWeight, style: Theme.of(context).textTheme.bodySmall),
        if (item.weight != null)
          Text(
            '${copy.weight}: ${copy.number(item.weight!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
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
        child: Icon(
          Icons.restaurant_menu,
          color: colors.mutedText,
          size: AppSizes.iconLarge,
        ),
      ),
    );
  }
}
