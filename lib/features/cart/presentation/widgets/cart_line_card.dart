import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/cart_mutation.dart';
import 'cart_quantity_stepper.dart';

enum CartLineMenuAction { edit, remove }

/// One cart line, laid out like the reference design: picture on the start
/// side, name + "more" menu on top, option/add-on summary underneath, and the
/// price with the quantity stepper on the bottom row.
///
/// The card renders whatever [line] it is given. The cubit already projects
/// quantity and line total the instant the customer taps, so nothing here
/// shows a "loading" state: numbers just change in place.
class CartLineCard extends StatelessWidget {
  const CartLineCard({
    required this.line,
    required this.isClearing,
    required this.onQuantityChanged,
    required this.onMenuAction,
    super.key,
  });

  final CartLine line;
  final bool isClearing;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<CartLineMenuAction> onMenuAction;

  static const double _imageSize = 88;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = l10n.cart;
    final arabic = l10n.locale.languageCode == 'ar';
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    final name = line.nameFor(arabic);
    final option = line.optionNameFor(arabic)?.trim() ?? '';
    final addons = line.addons
        .map((addon) => addon.nameFor(arabic))
        .where((value) => value.trim().isNotEmpty)
        .join(arabic ? '، ' : ', ');
    final details = <String>[
      if (option.isNotEmpty) option,
      if (addons.isNotEmpty) addons,
    ].join(arabic ? ' • ' : ' • ');

    final canDecrease = !isClearing && !line.isRemoved;
    final canIncrease =
        canDecrease && line.isAvailable && line.quantity < kMaxCartLineQuantity;
    final statusText = line.isRemoved
        ? copy.removed
        : !line.isAvailable
            ? copy.unavailable
            : null;

    return Semantics(
      label: '$name, ${copy.lineTotal}: ${copy.amount(line.lineTotal)}',
      child: DecoratedBox(
        key: Key('cart_line_${line.id}'),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.xlargeRadius,
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: AppRadius.largeRadius,
                child: SizedBox.square(
                  dimension: _imageSize,
                  child: AppNetworkImage(
                    url: line.imageUrl,
                    placeholder: ColoredBox(
                      color: colors.iconSurface,
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: colors.mutedText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: AppSpacing.xxs,
                            ),
                            child: Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.headingText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        _MoreMenu(
                          line: line,
                          canEdit: canDecrease,
                          onSelected: onMenuAction,
                        ),
                      ],
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.mutedText),
                      ),
                    if (statusText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          statusText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: AppSpacing.xxs,
                      children: <Widget>[
                        Text(
                          copy.amount(line.lineTotal),
                          key: Key('cart_line_total_${line.id}'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.headingText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        CartQuantityStepper(
                          quantity: line.quantity,
                          canDecrease: canDecrease,
                          canIncrease: canIncrease,
                          onDecrease: () => onQuantityChanged(-1),
                          onIncrease: () => onQuantityChanged(1),
                        ),
                      ],
                    ),
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

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.line,
    required this.canEdit,
    required this.onSelected,
  });

  final CartLine line;
  final bool canEdit;
  final ValueChanged<CartLineMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return PopupMenuButton<CartLineMenuAction>(
      key: ValueKey<String>('cart_more_${line.id}'),
      tooltip: copy.moreActions,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44),
      icon: Icon(Icons.more_horiz_rounded, color: colors.bodyText),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      onSelected: onSelected,
      itemBuilder: (context) => <PopupMenuEntry<CartLineMenuAction>>[
        PopupMenuItem<CartLineMenuAction>(
          key: ValueKey<String>('cart_edit_${line.id}'),
          value: CartLineMenuAction.edit,
          enabled: canEdit,
          child: Text(copy.editQuantity),
        ),
        PopupMenuItem<CartLineMenuAction>(
          key: ValueKey<String>('cart_remove_${line.id}'),
          value: CartLineMenuAction.remove,
          child: Text(
            copy.removeLine,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
