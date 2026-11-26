import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// Floating summary backed only by GetCount and GetMyCart snapshots.
class CartBar extends StatelessWidget {
  const CartBar({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final subTotal = state.subTotal;
        if (state.badgeQuantity <= 0 || subTotal == null) {
          return const SizedBox.shrink();
        }
        // The displayed count is the optimistic projection, so it is never
        // a stale value presented as current. The subtotal is not
        // client-projectable, so while changes are pending it is replaced
        // by a progress affordance instead of shown as current.
        final isSyncFailed = state.isSynchronizationFailure;
        final isPending =
            state.isMutating || state.isSynchronizing || isSyncFailed;
        final theme = Theme.of(context);
        final colors =
            theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
        final l10n = AppLocalizations.of(context);
        final title = l10n.cart.itemsInCart(state.totalQuantity);
        final total = l10n.cart.amount(subTotal);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Semantics(
            button: true,
            label: isSyncFailed
                ? '${l10n.cart.openCart}: $title, ${l10n.cart.synchronizationFailed}'
                : isPending
                    ? '${l10n.cart.openCart}: $title, ${l10n.cart.updating}'
                    : '${l10n.cart.openCart}: $title, $total',
            excludeSemantics: true,
            child: Material(
              key: const Key('cart_bar'),
              color: colors.primary,
              elevation: 6,
              shadowColor: colors.primary.withValues(alpha: .35),
              borderRadius: AppRadius.xlargeRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.onPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 44,
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      if (isSyncFailed)
                        Icon(
                          Icons.sync_problem_rounded,
                          color: colors.onPrimary,
                          size: 20,
                        )
                      else if (isPending)
                        SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      else
                        Text(
                          total,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colors.onPrimary,
                        textDirection: Directionality.of(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
