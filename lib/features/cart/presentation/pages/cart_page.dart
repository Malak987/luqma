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
  const CartPage({this.onBrowseRestaurants, super.key});

  final VoidCallback? onBrowseRestaurants;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
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
            onBrowseRestaurants: onBrowseRestaurants,
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
    this.onBrowseRestaurants,
    super.key,
  });

  final CartState state;
  final Future<void> Function() onRetry;
  final Future<CartMutationResult> Function()? onClearCart;
  final VoidCallback? onBrowseRestaurants;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
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
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _CenteredFeedback(
                    icon: Icons.shopping_cart_outlined,
                    title: copy.emptyTitle,
                    message: copy.emptyMessage,
                    action: _browseAction(copy),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _CartSyncBanner(onRetry: onRetry),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return _CenteredFeedback(
        key: const Key('cart_empty_state'),
        icon: Icons.shopping_cart_outlined,
        title: copy.emptyTitle,
        message: copy.emptyMessage,
        action: _browseAction(copy),
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
                  final compact = constraints.maxWidth < 360 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.45;
                  final title = Semantics(
                    header: true,
                    child: Row(
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: .10),
                            borderRadius: AppRadius.largeRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Icon(Icons.shopping_bag_outlined,
                                color: colors.link),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                            child: Text(
                          copy.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.headingText,
                            fontWeight: FontWeight.w800,
                          ),
                        )),
                      ],
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
                  isPending: state.isLineMutating(line),
                  pricesAreStale: state.pricesAreStale,
                  onRemove: () => _removeLine(context, line),
                  onEdit: () => _editQuantity(context, line),
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
              child: _SubtotalCard(
                subTotal: state.pricesAreStale ? null : cart.subTotal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _browseAction(CartTranslations copy) => onBrowseRestaurants == null
      ? null
      : AppButton(
          key: const Key('cart_browse_restaurants'),
          width: 220,
          text: copy.browseRestaurants,
          onPressed: onBrowseRestaurants,
        );

  Future<void> _editQuantity(BuildContext context, CartLine line) async {
    final cubit = context.read<CartCubit>();
    final copy = AppLocalizations.of(context).cart;
    final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final option = line.optionNameFor(arabic);
    final addons = line.addons
        .map((addon) => addon.nameFor(arabic))
        .where((name) => name.trim().isNotEmpty)
        .join(arabic ? '، ' : ', ');
    var target = line.quantity;
    var submitted = false;
    final media = MediaQuery.of(context);
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      sheetAnimationStyle: media.disableAnimations || media.accessibleNavigation
          ? AnimationStyle.noAnimation
          : null,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.editQuantity,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(line.nameFor(arabic),
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              if (option != null && option.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                _DetailText(label: copy.options, value: option),
              ],
              if (addons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                _DetailText(label: copy.addons, value: addons),
              ],
              const SizedBox(height: AppSpacing.md),
              _QuantityControl(
                quantity: target,
                canDecrease: target > 1,
                canIncrease: line.isAvailable && target < kMaxCartLineQuantity,
                onDecrease: () => setSheetState(() => target--),
                onIncrease: () => setSheetState(() => target++),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const Key('cart_edit_save'),
                text: copy.saveChanges,
                onPressed: () {
                  if (submitted) return;
                  submitted = true;
                  Navigator.of(sheetContext).pop(target);
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || selected == null) return;
    final matches = cubit.state.items
        .where(
          (item) => cartLineMutationKey(item) == cartLineMutationKey(line),
        )
        .toList();
    // Never apply an old editor value to a removed, ambiguous, or changed line.
    if (matches.length != 1 ||
        matches.single.id != line.id ||
        matches.single.quantity != line.quantity ||
        matches.single.isRemoved ||
        cubit.state.isClearing ||
        cubit.state.isLineMutating(matches.single) ||
        (selected > line.quantity && !matches.single.isAvailable)) {
      _showMessage(context, AppLocalizations.of(context).cart.lineChanged);
      return;
    }
    if (selected == line.quantity) return;
    final result = await cubit.updateLineQuantity(matches.single, selected);
    if (!context.mounted || result != CartMutationResult.failed) return;
    _showMessage(context, AppLocalizations.of(context).cart.actionFailed);
  }

  Future<void> _removeLine(BuildContext context, CartLine line) async {
    final cubit = context.read<CartCubit>();
    final l10n = AppLocalizations.of(context);
    final copy = l10n.cart;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlargeRadius),
        title: Text(copy.removeConfirmTitle),
        content: Text(copy.removeConfirmMessage(
            line.nameFor(l10n.locale.languageCode == 'ar'))),
        actions: <Widget>[
          TextButton(
              key: const Key('cart_remove_cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.common.cancel)),
          TextButton(
              key: const Key('cart_remove_confirm'),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(copy.confirmRemove)),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final matches = cubit.state.items
        .where((item) => cartLineMutationKey(item) == cartLineMutationKey(line))
        .toList();
    if (matches.length != 1 ||
        matches.single.id != line.id ||
        matches.single.quantity != line.quantity ||
        matches.single.isRemoved ||
        cubit.state.isClearing ||
        cubit.state.isLineMutating(matches.single)) {
      _showMessage(context, copy.lineChanged);
      return;
    }
    final result = await cubit.updateLineQuantity(matches.single, 0);
    if (!context.mounted || result != CartMutationResult.failed) return;
    _showMessage(context, copy.actionFailed);
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlargeRadius),
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
      FailureCode.network => copy.loadFailedMessage,
      FailureCode.validation => copy.loadRetryMessage,
      FailureCode.invalidCredentials => copy.loadRetryMessage,
      FailureCode.unknown || null => copy.loadRetryMessage,
    };
  }
}

class CartLineTile extends StatelessWidget {
  const CartLineTile({
    required this.line,
    required this.isClearing,
    required this.onQuantityChanged,
    this.onRemove,
    this.onEdit,
    this.isPending = false,
    this.pricesAreStale = false,
    super.key,
  });

  final CartLine line;
  final bool isClearing;
  final bool isPending;
  final bool pricesAreStale;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;
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
      label:
          '$name, ${copy.lineTotal}: ${pricesAreStale ? copy.pricesPending : copy.amount(line.lineTotal)}',
      child: Card(
        key: Key('cart_line_${line.id}'),
        margin: EdgeInsets.zero,
        color: (Theme.of(context).extension<AppSemanticColors>() ??
                AppSemanticColors.light)
            .surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlargeRadius,
          side: BorderSide(
            color: (Theme.of(context).extension<AppSemanticColors>() ??
                    AppSemanticColors.light)
                .border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.45;
              final details = _LineDetails(
                line: line,
                option: option,
                addonNames: addonNames,
                canDecrease: canDecrease,
                canIncrease: canIncrease,
                onQuantityChanged: onQuantityChanged,
                onRemove: onRemove,
                onEdit: onEdit,
                isPending: isPending,
                pricesAreStale: pricesAreStale,
              );
              // On narrow displays the image remains alongside the title and
              // controls move below, rather than shrinking touch targets.
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _LineImage(url: line.imageUrl),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child: Text(name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: (Theme.of(context).extension<
                                                      AppSemanticColors>() ??
                                                  AppSemanticColors.light)
                                              .headingText,
                                          fontWeight: FontWeight.w800))),
                        ]),
                    const SizedBox(height: AppSpacing.sm),
                    _LineDetails(
                      line: line,
                      option: option,
                      addonNames: addonNames,
                      canDecrease: canDecrease,
                      canIncrease: canIncrease,
                      onQuantityChanged: onQuantityChanged,
                      onRemove: onRemove,
                      onEdit: onEdit,
                      isPending: isPending,
                      pricesAreStale: pricesAreStale,
                      showName: false,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _LineImage(url: line.imageUrl),
                  const SizedBox(width: AppSpacing.md),
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
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return ClipRRect(
      borderRadius: AppRadius.largeRadius,
      child: SizedBox.square(
        dimension: 84,
        child: AppNetworkImage(
          url: url,
          placeholder: ColoredBox(
            color: colors.iconSurface,
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
    required this.onRemove,
    required this.onEdit,
    required this.isPending,
    required this.pricesAreStale,
    this.showName = true,
  });

  final bool showName;
  final CartLine line;
  final String? option;
  final String addonNames;
  final bool canDecrease;
  final bool canIncrease;
  final bool isPending;
  final bool pricesAreStale;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;
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
        if (showName)
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.bodyText,
              fontWeight: FontWeight.w800,
            ),
          ),
        if (isPending) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          _CartStatusLine(message: copy.updating),
        ],
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
        DecoratedBox(
          decoration: BoxDecoration(
              color: colors.iconSurface, borderRadius: AppRadius.mediumRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                      '${copy.unitPrice}: ${pricesAreStale ? copy.pricesPending : copy.amount(line.unitPrice)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.mutedText)),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                      '${copy.lineTotal}: ${pricesAreStale ? copy.pricesPending : copy.amount(line.lineTotal)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.headingText,
                          fontWeight: FontWeight.w800)),
                ]),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _QuantityControl(
              quantity: line.quantity,
              canDecrease: canDecrease,
              canIncrease: canIncrease,
              onDecrease: () => onQuantityChanged(-1),
              onIncrease: () => onQuantityChanged(1),
            ),
            if (onEdit != null)
              IconButton(
                key: ValueKey('cart_edit_${line.id}'),
                tooltip: copy.editQuantity,
                onPressed: canDecrease && !isPending ? onEdit : null,
                icon: const Icon(Icons.edit_outlined),
              ),
            if (onRemove != null)
              IconButton(
                key: ValueKey('cart_remove_${line.id}'),
                tooltip: copy.removeLine,
                color: theme.colorScheme.error,
                onPressed: canDecrease ? onRemove : null,
                icon: const Icon(Icons.delete_outline_rounded),
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
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: AppRadius.smallRadius,
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodySmall?.copyWith(color: colors.mutedText),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
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
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Semantics(
      label: copy.itemsInCart(quantity),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.elevatedSurface,
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

  final num? subTotal;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.xlargeRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .10),
                    borderRadius: AppRadius.smallRadius),
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child:
                        Icon(Icons.receipt_long_outlined, color: colors.link)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text(copy.orderSummary,
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.headingText,
                          fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: AppSpacing.md),
            Divider(color: colors.divider, height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(children: <Widget>[
              Expanded(
                  child: Text(copy.subTotal,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: colors.mutedText))),
              Flexible(
                  child: Text(
                      subTotal == null
                          ? copy.pricesPending
                          : copy.amount(subTotal!),
                      textAlign: TextAlign.end,
                      key: const Key('cart_subtotal'),
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.headingText,
                          fontWeight: FontWeight.w800))),
            ]),
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
            color: colors.link,
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
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (loading)
              Semantics(
                liveRegion: true,
                label: title,
                child: SizedBox.square(
                  dimension: 40,
                  child: MediaQuery.disableAnimationsOf(context)
                      ? Icon(Icons.hourglass_empty_rounded,
                          color: colors.link, size: 36)
                      : CircularProgressIndicator(
                          strokeWidth: 3, color: colors.link),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: colors.link),
              ),
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
