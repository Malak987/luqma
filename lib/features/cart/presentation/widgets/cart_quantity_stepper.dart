import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The compact "−  1  +" control used by cart cards: an outlined minus, the
/// quantity, and a filled plus in the app's primary colour.
///
/// It is purely presentational and direction-aware (a [Row] flips in RTL), and
/// each button keeps a 44dp touch target around its 28dp visual.
class CartQuantityStepper extends StatelessWidget {
  const CartQuantityStepper({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
    this.decreaseLabel,
    this.increaseLabel,
    super.key,
  });

  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String? decreaseLabel;
  final String? increaseLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Semantics(
      container: true,
      label: l10n.cart.itemsInCart(quantity),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            key: const Key('cart_step_decrease'),
            icon: Icons.remove_rounded,
            label: decreaseLabel ?? l10n.cart.decrease,
            filled: false,
            onPressed: canDecrease ? onDecrease : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24),
            child: Text(
              l10n.catalog.number(quantity),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.bodyText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepButton(
            key: const Key('cart_step_increase'),
            icon: Icons.add_rounded,
            label: increaseLabel ?? l10n.cart.increase,
            filled: true,
            onPressed: canIncrease ? onIncrease : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final enabled = onPressed != null;
    final background = filled ? colors.primary : Colors.transparent;
    final foreground = filled ? colors.onPrimary : colors.bodyText;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : .38,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background,
                  border: filled
                      ? null
                      : Border.all(color: colors.elevatedBorder, width: 1.2),
                ),
                child: SizedBox.square(
                  dimension: 28,
                  child: Icon(icon, size: 18, color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
