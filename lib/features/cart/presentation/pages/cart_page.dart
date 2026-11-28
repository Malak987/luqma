import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../address/domain/entities/address.dart';
import '../../../address/presentation/cubit/address_setup_cubit.dart';
import '../../../address/presentation/cubit/address_setup_state.dart';
import '../../../address/presentation/widgets/address_manager_sheet.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/translations/cart_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/cart_mutation.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/cart_checkout_panel.dart';
import '../widgets/cart_line_card.dart';
import '../widgets/cart_quantity_stepper.dart';
import '../widgets/cart_swipe_reveal.dart';

/// The Cart tab. It renders only server-supplied cart lines and totals.
///
/// Quantity changes are projected by [CartCubit] the instant the customer
/// taps, so this page never shows a loading or "updating" state for them. The
/// builder below also ignores state changes that have no visible effect (the
/// silent background reconcile), so the screen is not rebuilt for them.
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
          buildWhen: _affectsVisibleUi,
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

  /// Ignore background bookkeeping that has no visible effect. Price staleness
  /// is visible in the summary and must trigger an update.
  static bool _affectsVisibleUi(CartState previous, CartState current) =>
      previous.status != current.status ||
      previous.cart != current.cart ||
      previous.pricesAreStale != current.pricesAreStale ||
      previous.isClearing != current.isClearing ||
      previous.failure != current.failure ||
      previous.isSynchronizationFailure != current.isSynchronizationFailure;
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
      return Column(
        children: <Widget>[
          _CartHeader(state: state, onClearCart: null, onConfirmClear: null),
          if (state.isSynchronizationFailure)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _CartSyncBanner(onRetry: onRetry),
            ),
          Expanded(
            child: _CenteredFeedback(
              key: const Key('cart_empty_state'),
              icon: Icons.shopping_cart_outlined,
              title: copy.emptyTitle,
              message: copy.emptyMessage,
              action: _browseAction(copy),
            ),
          ),
        ],
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

    final canCheckout = !state.isClearing &&
        cart.items.every((line) => line.isAvailable && !line.isRemoved);

    return Column(
      key: const Key('cart_populated_state'),
      children: <Widget>[
        _CartHeader(
          state: state,
          onClearCart: onClearCart,
          onConfirmClear: () => _confirmClearCart(context),
        ),
        if (state.isSynchronizationFailure)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _CartSyncBanner(onRetry: onRetry),
          ),
        Expanded(
          child: RefreshIndicator(
            color: colors.primary,
            onRefresh: onRetry,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              findItemIndexCallback: (key) {
                if (key is! ValueKey<String>) return null;
                final index = cart.items.indexWhere(
                  (line) => key.value == cartLineMutationKey(line),
                );
                return index < 0 ? null : index;
              },
              itemBuilder: (context, index) {
                final line = cart.items[index];
                final name = line.nameFor(
                  AppLocalizations.of(context).locale.languageCode == 'ar',
                );
                return CartSwipeReveal(
                  // Stable identity: a neighbour changing never rebuilds this
                  // row's state (open/closed swipe, image).
                  key: ValueKey<String>(cartLineMutationKey(line)),
                  deleteLabel: copy.removeLine,
                  onDelete: () => _removeLine(context, line, name),
                  child: CartLineCard(
                    line: line,
                    isClearing: state.isClearing,
                    onQuantityChanged: (delta) =>
                        _changeQuantity(context, line, delta, name),
                    onMenuAction: (action) {
                      switch (action) {
                        case CartLineMenuAction.edit:
                          _editQuantity(context, line);
                        case CartLineMenuAction.remove:
                          _removeLine(context, line, name);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
        CartCheckoutPanel(
          subTotal: cart.subTotal,
          pricesAreStale: state.pricesAreStale,
          addressSection: const _CartAddressSection(),
          canCheckout: canCheckout,
          onApplyPromo: (_) => _showMessage(context, copy.promoUnavailable),
          onCheckout: () => _showMessage(context, copy.checkoutUnavailable),
        ),
      ],
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

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  /// Removal is immediate and reversible: the row disappears at once (the
  /// cubit projects it) and an Undo action puts the same configuration back.
  Future<void> _removeLine(
    BuildContext context,
    CartLine line,
    String name,
  ) async {
    final cubit = context.read<CartCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final copy = AppLocalizations.of(context).cart;
    final pending = cubit.updateLineQuantity(line, 0);
    _showUndo(messenger, cubit, copy, line, name);
    final result = await pending;
    if (result != CartMutationResult.failed) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copy.actionFailed)));
  }

  Future<void> _changeQuantity(
    BuildContext context,
    CartLine line,
    int delta,
    String name,
  ) async {
    final cubit = context.read<CartCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final copy = AppLocalizations.of(context).cart;
    final removesLine = cubit.quantityAfterDelta(line, delta) <= 0;
    // The new quantity is already on screen; only a failure needs a message.
    final pending = cubit.changeLineQuantityBy(line, delta);
    if (removesLine) _showUndo(messenger, cubit, copy, line, name);
    final result = await pending;
    if (result != CartMutationResult.failed) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copy.actionFailed)));
  }

  void _showUndo(
    ScaffoldMessengerState messenger,
    CartCubit cubit,
    CartTranslations copy,
    CartLine line,
    String name,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(copy.itemRemoved(name)),
          action: SnackBarAction(
            label: copy.undo,
            onPressed: () async {
              final result = await cubit.add(
                menuItemId: line.menuItemId,
                quantity: line.quantity,
                menuItemOptionId: line.menuItemOptionId,
                addonIds: line.addons
                    .map((addon) => addon.id)
                    .toList(growable: false),
              );
              if (result != CartMutationResult.failed &&
                  result != CartMutationResult.storeConflict) {
                return;
              }
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(copy.actionFailed)));
            },
          ),
        ),
      );
  }

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
            children: <Widget>[
              Text(copy.editQuantity,
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(line.nameFor(arabic),
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              if (option != null && option.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text('${copy.options}: $option'),
              ],
              if (addons.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text('${copy.addons}: $addons'),
              ],
              const SizedBox(height: AppSpacing.md),
              CartQuantityStepper(
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
        matches.single.isRemoved ||
        cubit.state.isClearing ||
        (selected > line.quantity && !matches.single.isAvailable)) {
      _showMessage(context, copy.lineChanged);
      return;
    }
    if (selected == matches.single.quantity) return;
    final result = await cubit.updateLineQuantity(matches.single, selected);
    if (!context.mounted || result != CartMutationResult.failed) return;
    _showMessage(context, copy.actionFailed);
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

/// Header from the reference design: optional round back button, the title with
/// the item count, and a round action button (clear cart) on the END side.
class _CartAddressSection extends StatelessWidget {
  const _CartAddressSection();
  @override
  Widget build(BuildContext context) {
    AddressSetupCubit? cubit;
    try {
      cubit = context.read<AddressSetupCubit>();
    } catch (_) {
      return const SizedBox.shrink();
    }
    return BlocSelector<AddressSetupCubit, AddressSetupState, Address?>(
      bloc: cubit,
      selector: (state) => state.selectedAddress,
      builder: (context, address) {
        final colors = Theme.of(context).extension<AppSemanticColors>() ??
            AppSemanticColors.light;
        final copy = AppLocalizations.of(context).cart;
        final value = address == null
            ? copy.addressNotSelected
            : [address.title, address.district, address.city]
                .where((s) => s.trim().isNotEmpty)
                .join('، ');
        return Material(
            color: colors.iconSurface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => showAddressManagerSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(children: [
                    Icon(Icons.location_on_outlined, color: colors.link),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(copy.savedAddress,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: colors.mutedText)),
                          Text(value,
                              style: Theme.of(context).textTheme.bodyMedium)
                        ])),
                    const SizedBox(width: AppSpacing.xs),
                    Text(copy.changeAddress,
                        style: TextStyle(color: colors.link)),
                  ])),
            ));
      },
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.state,
    required this.onClearCart,
    required this.onConfirmClear,
  });

  final CartState state;
  final Future<CartMutationResult> Function()? onClearCart;
  final VoidCallback? onConfirmClear;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).cart;
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          if (canPop) ...<Widget>[
            _CircleAction(
              key: const Key('cart_back_button'),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              // The arrow flips with the text direction, so it always points
              // toward "back" in both Arabic and English.
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colors.bodyText,
                textDirection: Directionality.of(context),
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    copy.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.headingText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (state.totalQuantity > 0)
                    Text(
                      copy.itemsInCart(state.totalQuantity),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (onClearCart != null && onConfirmClear != null)
            _CircleAction(
              key: const Key('cart_clear_button'),
              tooltip: copy.clear,
              icon: state.isClearing
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Icon(
                      Icons.remove_shopping_cart_outlined,
                      color: colors.bodyText,
                    ),
              onPressed: state.isClearing ? null : onConfirmClear,
            ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Material(
      color: colors.surface,
      shape: CircleBorder(side: BorderSide(color: colors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox.square(dimension: 44, child: Center(child: icon)),
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
