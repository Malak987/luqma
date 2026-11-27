import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/translations/cart_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/cart_mutation.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';

/// The Cart tab. It renders only server-supplied cart lines and totals.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Scaffold(
      key: const Key('cart_page'),
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) => CartPageContent(
            state: state,
            onRetry: () => context.read<CartCubit>().refresh(force: true),
            onClearCart: context.read<CartCubit>().clearCart,
          ),
        ),
      ),
    );
  }
}

/// Separating state rendering keeps loading/error/empty/populated UI testable
/// without putting networking behavior in a widget.
class CartPageContent extends StatelessWidget {
  const CartPageContent({
    required this.state,
    required this.onRetry,
    this.onClearCart,
    super.key,
  });

  final CartState state;
  final Future<void> Function() onRetry;
  final Future<CartMutationResult> Function()? onClearCart;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final theme = Theme.of(context);

    if ((state.status == CartStatus.initial || state.isLoading) &&
        state.cart == null) {
      return _CenteredFeedback(
        key: const Key('cart_loading_state'),
        icon: Icons.shopping_cart_outlined,
        title: copy.loading,
        message: copy.loading,
        loading: true,
      );
    }
    if (state.hasError && state.cart == null) {
      return _CenteredFeedback(
        key: const Key('cart_error_state'),
        icon: Icons.cloud_off_outlined,
        title: copy.loadFailed,
        message: state.isSynchronizationFailure
            ? copy.synchronizationFailed
            : _messageFor(copy, state.failure),
        action: AppButton(
          key: const Key('cart_retry_button'),
          width: 220,
          text: copy.retry,
          onPressed: () => onRetry(),
        ),
      );
    }
    if (state.isEmpty) {
      if (state.isSynchronizationFailure) {
        return Column(
          children: <Widget>[
            const Spacer(),
            _CenteredFeedback(
              icon: Icons.shopping_cart_outlined,
              title: copy.emptyTitle,
              message: copy.emptyMessage,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _CartSyncBanner(onRetry: onRetry),
            ),
            const Spacer(),
          ],
        );
      }
      return _CenteredFeedback(
        key: const Key('cart_empty_state'),
        icon: Icons.shopping_cart_outlined,
        title: copy.emptyTitle,
        message: copy.emptyMessage,
      );
    }

    final cart = state.cart;
    if (cart == null) {
      return _CenteredFeedback(
        key: const Key('cart_loading_state'),
        icon: Icons.shopping_cart_outlined,
        title: copy.loading,
        message: copy.loading,
        loading: true,
      );
    }

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: onRetry,
      child: CustomScrollView(
        key: const Key('cart_populated_state'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 360 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.45;
                  final title = Semantics(
                    header: true,
                    child: Text(
                      copy.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.headingText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                  final itemCount = Text(
                    copy.itemsInCart(state.totalQuantity),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                  final clearAction = onClearCart == null
                      ? null
                      : TextButton.icon(
                          key: const Key('cart_clear_button'),
                          onPressed: state.isMutating
                              ? null
                              : () => _confirmClearCart(context),
                          icon: state.isClearing
                              ? SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primary,
                                  ),
                                )
                              : const Icon(Icons.remove_shopping_cart_outlined),
                          label: Text(copy.clear),
                        );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        title,
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              itemCount,
                              if (clearAction != null) clearAction,
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: title),
                      Flexible(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            itemCount,
                            if (clearAction != null) clearAction,
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: state.isSynchronizing || state.isMutating
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CartStatusLine(
                        // A line change outranks the quieter reconcile copy.
                        message: state.isMutating
                            ? copy.updating
                            : copy.synchronizing,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: state.isSynchronizationFailure
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CartSyncBanner(onRetry: onRetry),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList.separated(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final line = cart.items[index];
                return CartLineTile(
                  // Stable identity keeps rows (and their images) from being
                  // rebuilt when a neighbour changes.
                  key: ValueKey<String>(cartLineMutationKey(line)),
                  line: line,
                  isClearing: state.isClearing,
                  onQuantityChanged: (delta) =>
                      _changeQuantity(context, line, delta),
                );
              },
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: _SubtotalCard(subTotal: cart.subTotal),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeQuantity(
    BuildContext context,
    CartLine line,
    int delta,
  ) async {
    // The new quantity is already on screen; only a failure needs a message.
    final result =
        await context.read<CartCubit>().changeLineQuantityBy(line, delta);
    if (!context.mounted || result != CartMutationResult.failed) return;
    _showMessage(context, AppLocalizations.of(context).cart.actionFailed);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final clearCart = onClearCart;
    if (clearCart == null) return;
    final l10n = AppLocalizations.of(context);
    final copy = l10n.cart;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.clearConfirmTitle),
        content: Text(copy.clearConfirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.common.cancel),
          ),
          TextButton(
            key: const Key('cart_clear_confirm_button'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(copy.clear),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await clearCart();
    if (!context.mounted || result == CartMutationResult.busy) return;
    _showMessage(
      context,
      result == CartMutationResult.success ? copy.cleared : copy.actionFailed,
    );
  }

  String _messageFor(CartTranslations copy, Failure? failure) {
    return switch (failure?.code) {
      FailureCode.network => copy.actionFailed,
      FailureCode.validation => copy.actionFailed,
      FailureCode.invalidCredentials => copy.actionFailed,
      FailureCode.unknown || null => copy.actionFailed,
    };
  }
}

class CartLineTile extends StatelessWidget {
  const CartLineTile({
    required this.line,
    required this.isClearing,
    required this.onQuantityChanged,
    super.key,
  });

  final CartLine line;
  final bool isClearing;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final name = line.nameFor(arabic);
    final option = line.optionNameFor(arabic);
    final addonNames = line.addons
        .map((addon) => addon.nameFor(arabic))
        .where((name) => name.trim().isNotEmpty)
        .join(arabic ? '، ' : ', ');
    // Unavailable lines cannot be increased but can always be removed.
    // Quantity is capped at the documented maximum of 99.
    final canDecrease = !isClearing && !line.isRemoved;
    final canIncrease =
        canDecrease && line.isAvailable && line.quantity < kMaxCartLineQuantity;

    return Semantics(
      label: '$name, ${copy.lineTotal}: ${copy.amount(line.lineTotal)}',
      child: Card(
        key: Key('cart_line_${line.id}'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 330 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.45;
              final details = _LineDetails(
                line: line,
                option: option,
                addonNames: addonNames,
                canDecrease: canDecrease,
                canIncrease: canIncrease,
                onQuantityChanged: onQuantityChanged,
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _LineImage(url: line.imageUrl),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    details,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _LineImage(url: line.imageUrl),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: details),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LineImage extends StatelessWidget {
  const _LineImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return ClipRRect(
      borderRadius: AppRadius.largeRadius,
      child: SizedBox.square(
        dimension: 76,
        child: AppNetworkImage(
          url: url,
          placeholder: ColoredBox(
            color: colors.elevatedSurface,
            child: Icon(Icons.restaurant_menu, color: colors.mutedText),
          ),
        ),
      ),
    );
  }
}

class _LineDetails extends StatelessWidget {
  const _LineDetails({
    required this.line,
    required this.option,
    required this.addonNames,
    required this.canDecrease,
    required this.canIncrease,
    required this.onQuantityChanged,
  });

  final CartLine line;
  final String? option;
  final String addonNames;
  final bool canDecrease;
  final bool canIncrease;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final name = line.nameFor(arabic);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (option != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          _DetailText(label: copy.options, value: option!),
        ],
        if (addonNames.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          _DetailText(label: copy.addons, value: addonNames),
        ],
        if (line.isRemoved || !line.isAvailable) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          _StatusPill(text: line.isRemoved ? copy.removed : copy.unavailable),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: AppSpacing.xs,
          spacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${copy.unitPrice}: ${copy.amount(line.unitPrice)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
                Text(
                  '${copy.lineTotal}: ${copy.amount(line.lineTotal)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.headingText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            _QuantityControl(
              quantity: line.quantity,
              canDecrease: canDecrease,
              canIncrease: canIncrease,
              // UpdateToCart(quantity: 0) removes this exact configuration.
              // The Cubit sends the line's server-provided option/add-on IDs.
              onDecrease: () => onQuantityChanged(-1),
              onIncrease: () => onQuantityChanged(1),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Text(
      '$label: $value',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(color: colors.mutedText),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .1),
        borderRadius: AppRadius.smallRadius,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.headingText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Semantics(
      label: copy.itemsInCart(quantity),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: quantity > 1 ? copy.decrease : copy.remove,
              onPressed: canDecrease ? onDecrease : null,
              icon: const Icon(Icons.remove_rounded),
              visualDensity: VisualDensity.compact,
            ),
            Text(
              AppLocalizations.of(context).catalog.number(quantity),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              tooltip: copy.increase,
              onPressed: canIncrease ? onIncrease : null,
              icon: const Icon(Icons.add_rounded),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubtotalCard extends StatelessWidget {
  const _SubtotalCard({required this.subTotal});

  final num subTotal;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        border: Border.all(color: colors.elevatedBorder),
        borderRadius: AppRadius.xlargeRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                copy.subTotal,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.headingText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              copy.amount(subTotal),
              key: const Key('cart_subtotal'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSyncBanner extends StatelessWidget {
  const _CartSyncBanner({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onErrorContainer;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.sm,
          top: AppSpacing.xxs,
          bottom: AppSpacing.xxs,
          end: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: AppRadius.mediumRadius,
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.sync_problem_rounded, color: foreground, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                copy.synchronizationFailed,
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
            IconButton(
              tooltip: copy.retry,
              onPressed: () => onRetry(),
              icon: Icon(Icons.refresh_rounded, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet, non-blocking progress copy: "Updating cart" while a line change is
/// still being confirmed, "Syncing cart" while the reconcile runs.
class _CartStatusLine extends StatelessWidget {
  const _CartStatusLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        key: const Key('cart_status_line'),
        children: <Widget>[
          // A static glyph, not a spinner: an indeterminate animation here
          // would keep `pumpAndSettle` spinning in widget tests.
          Icon(
            Icons.sync_rounded,
            size: 16,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredFeedback extends StatelessWidget {
  const _CenteredFeedback({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (loading)
              SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.primary,
                ),
              )
            else
              Icon(icon, size: 64, color: colors.mutedText),
            const SizedBox(height: AppSpacing.lg),
            if (!loading)
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!loading) const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.mutedText,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
