import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// Floating summary of the cart. Invisible while the cart is empty.
///
/// It is meant to sit directly above the persistent navigation bar, so pages
/// use it as their `bottomNavigationBar`.
class CartBar extends StatelessWidget {
  const CartBar({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        if (state.isEmpty) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final colors = theme.extension<AppSemanticColors>() ??
            AppSemanticColors.light;
        final l10n = AppLocalizations.of(context);
        final arabic = l10n.locale.languageCode == 'ar';
        final store = state.store;
        final storeName =
            store == null ? '' : (arabic ? store.nameAr : store.nameEn);
        final title = l10n.cart.itemsInCart(state.itemCount);
        final total = l10n.cart.amount(state.total);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Semantics(
            button: true,
            label: '${l10n.cart.openCart}: $title, $storeName, $total',
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
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.onPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: 44,
                          child: Icon(Icons.shopping_bag_rounded,
                              color: colors.primary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (storeName.isNotEmpty)
                              Text(
                                storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onPrimary
                                      .withValues(alpha: .85),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        total,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.arrow_forward_rounded,
                          color: colors.onPrimary),
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
