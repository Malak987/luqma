import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

/// Bottom panel of the cart: promo code, order summary and the checkout
/// button. It holds only the promo text; amounts come from the cart state.
///
/// The backend has no promo-code or delivery-fee contract yet, so [onApplyPromo]
/// and [onCheckout] are owned by the page, and the delivery row says the fee is
/// calculated at checkout instead of inventing a number.
class CartCheckoutPanel extends StatefulWidget {
  const CartCheckoutPanel({
    required this.subTotal,
    required this.canCheckout,
    required this.onApplyPromo,
    required this.onCheckout,
    super.key,
  });

  final num subTotal;
  final bool canCheckout;
  final ValueChanged<String> onApplyPromo;
  final VoidCallback onCheckout;

  @override
  State<CartCheckoutPanel> createState() => _CartCheckoutPanelState();
}

class _CartCheckoutPanelState extends State<CartCheckoutPanel> {
  final TextEditingController _promo = TextEditingController();

  @override
  void dispose() {
    _promo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final maxHeight = MediaQuery.sizeOf(context).height * .55;
    final amount = copy.amount(widget.subTotal);

    return DecoratedBox(
      key: const Key('cart_checkout_panel'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _PromoField(
                controller: _promo,
                hint: copy.promoCode,
                applyLabel: copy.apply,
                onApply: () => widget.onApplyPromo(_promo.text.trim()),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                copy.orderSummary,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.headingText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _SummaryRow(
                label: copy.subTotal,
                value: amount,
                valueKey: const Key('cart_subtotal'),
              ),
              const SizedBox(height: AppSpacing.xxs),
              _SummaryRow(
                label: copy.deliveryShipping,
                value: copy.deliveryAtCheckout,
                muted: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1, color: colors.divider),
              ),
              _SummaryRow(
                label: copy.total,
                value: amount,
                strong: true,
                valueKey: const Key('cart_total'),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const Key('cart_checkout_button'),
                text: copy.checkout,
                height: 56,
                borderRadius: AppRadius.pillRadius,
                enabled: widget.canCheckout,
                onPressed: widget.canCheckout ? widget.onCheckout : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoField extends StatelessWidget {
  const _PromoField({
    required this.controller,
    required this.hint,
    required this.applyLabel,
    required this.onApply,
  });

  final TextEditingController controller;
  final String hint;
  final String applyLabel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.iconSurface,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              key: const Key('cart_promo_field'),
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onApply(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.bodyText,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.mutedText,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.md,
                  end: AppSpacing.xs,
                  top: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              color: colors.primary,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('cart_promo_apply'),
                onTap: onApply,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    minWidth: 84,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        applyLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueKey,
    this.muted = false,
    this.strong = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool muted;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final labelStyle = (strong
            ? theme.textTheme.titleMedium
            : theme.textTheme.bodyMedium)
        ?.copyWith(
      color: strong ? colors.headingText : colors.mutedText,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
    );
    final valueStyle = (strong
            ? theme.textTheme.titleMedium
            : theme.textTheme.bodyMedium)
        ?.copyWith(
      color: muted
          ? colors.mutedText
          : strong
              ? colors.headingText
              : colors.bodyText,
      fontWeight: muted ? FontWeight.w500 : FontWeight.w800,
    );
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            key: valueKey,
            textAlign: TextAlign.end,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}
