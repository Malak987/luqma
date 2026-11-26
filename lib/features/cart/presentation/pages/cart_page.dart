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
            onRetry: context.read<CartCubit>().refresh,
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
    final pendingMessage = state.isSynchronizationFailure
        ? copy.synchronizationFailed
        : state.isSynchronizing
            ? copy.synchronizing
            : copy.updating;

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
      if (state.isSynchronizing || state.isSynchronizationFailure) {
        return Column(
          children: <Widget>[
            const Spacer(),
            _CenteredFeedback(
              icon: Icons.shopping_cart_outlined,
              title: copy.emptyTitle,
              message: copy.emptyMessage,
            ),
            if (state.isSynchronizing || state.isSynchronizationFailure)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _CartSyncBanner(
                  loading: state.isSynchronizing,
                  failed: state.isSynchronizationFailure,
                  synchronizationFailure: state.isSynchronizationFailure,
                  onRetry: onRetry,
                ),
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
                    state.isMutating || state.isSynchronizing
                        ? pendingMessage
                        : copy.itemsInCart(state.totalQuantity),
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
              child: state.isSynchronizing || state.isSynchronizationFailure
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CartSyncBanner(
                        loading: state.isSynchronizing,
                        failed: state.isSynchronizationFailure,
                        synchronizationFailure:
                            state.isSynchronizationFailure,
                        onRetry: onRetry,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList.separated(
              itemCount: cart.items.length,
              itemBuilder: (context, index) => CartLineTile(
                line: cart.items[index],
                isMutating: state.isLineMutating(cart.items[index]),
                isClearing: state.isClearing,
                isCartPending: state.isMutating ||
                    state.isSynchronizing ||
                    state.isSynchronizationFailure,
                pendingMessage: pendingMessage,
                onQuantityChanged: (delta) =>
                    _changeQuantity(context, cart.items[index], delta),
              ),
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
              child: _SubtotalCard(
                subTotal: cart.subTotal,
                isPending: state.isMutating ||
                    state.isSynchronizing ||
                    state.isSynchronizationFailure,
                pendingMessage: pendingMessage,
              ),
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
    final cubit = context.read<CartCubit>();
    final requestedQuantity = cubit.quantityAfterDelta(line, delta);
    final result = await cubit.changeLineQuantityBy(line, delta);
    if (!context.mounted || result == CartMutationResult.busy) return;
    final copy = AppLocalizations.of(context).cart;
    final message = switch (result) {
      CartMutationResult.success =>
        requestedQuantity == 0 ? copy.removed : copy.updated,
      CartMutationResult.synchronizationFailed => copy.synchronizationFailed,
      CartMutationResult.failed => copy.actionFailed,
      CartMutationResult.busy => '',
    };
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
    final message = switch (result) {
      CartMutationResult.success => copy.cleared,
      CartMutationResult.synchronizationFailed => copy.synchronizationFailed,
      CartMutationResult.failed => copy.actionFailed,
      CartMutationResult.busy => '',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    required this.isMutating,
    required this.isClearing,
    required this.isCartPending,
    required this.pendingMessage,
    required this.onQuantityChanged,
    super.key,
  });

  final CartLine line;
  final bool isMutating;
  final bool isClearing;
  final bool isCartPending;
  final String pendingMessage;
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
      label: isCartPending
          ? '$name, $pendingMessage'
          : '${name}, ${copy.lineTotal}: ${copy.amount(line.lineTotal)}',
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
                isMutating: isMutating,
                isCartPending: isCartPending,
                pendingMessage: pendingMessage,
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
    required this.isMutating,
    required this.isCartPending,
    required this.pendingMessage,
    required this.onQuantityChanged,
  });

  final CartLine line;
  final String? option;
  final String addonNames;
  final bool canDecrease;
  final bool canIncrease;
  final bool isMutating;
  final bool isCartPending;
  final String pendingMessage;
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
                  isCartPending
                      ? pendingMessage
                      : '${copy.lineTotal}: ${copy.amount(line.lineTotal)}',
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
              isMutating: isMutating,
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
    required this.isMutating,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final bool isMutating;
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
            if (isMutating)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: SizedBox.square(
                  dimension: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colors.primary,
                  ),
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
  const _SubtotalCard({
    required this.subTotal,
    required this.isPending,
    required this.pendingMessage,
  });

  final num subTotal;
  final bool isPending;
  final String pendingMessage;

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
              isPending ? pendingMessage : copy.amount(subTotal),
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
  const _CartSyncBanner({
    required this.loading,
    required this.failed,
    required this.synchronizationFailure,
    required this.onRetry,
  });

  final bool loading;
  final bool failed;
  final bool synchronizationFailure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final theme = Theme.of(context);
    final colors = theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final foreground = failed
        ? theme.colorScheme.onErrorContainer
        : colors.bodyText;
    final background = failed
        ? theme.colorScheme.errorContainer
        : colors.elevatedSurface;
    final message = loading
        ? copy.synchronizing
        : synchronizationFailure
            ? copy.synchronizationFailed
            : copy.actionFailed;

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
          color: background,
          borderRadius: AppRadius.mediumRadius,
        ),
        child: Row(
          children: <Widget>[
            if (loading)
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            else
              Icon(Icons.sync_problem_rounded, color: foreground, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
            if (failed)
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
              CircularProgressIndicator(color: colors.primary)
            else
              Icon(icon, size: 64, color: colors.mutedText),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
