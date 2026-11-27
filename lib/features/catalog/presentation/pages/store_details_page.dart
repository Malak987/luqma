import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/widgets/cart_bar.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/store.dart';
import '../cubit/store_menu_cubit.dart';
import '../cubit/store_menu_state.dart';
import '../widgets/menu_category_tabs.dart';
import '../widgets/menu_filters.dart';
import '../widgets/menu_item_details_sheet.dart';
import '../widgets/menu_item_results_slivers.dart';
import '../widgets/store_details_header.dart';

/// Store page: hero + info card, pinned category chips, the menu, and the cart
/// bar above the persistent navigation bar.
class StoreDetailsPage extends StatefulWidget {
  const StoreDetailsPage({required this.store, this.onOpenCart, super.key});
  final Store store;

  /// Opens the cart destination. Provided by the router so this page never
  /// reaches into the app shell.
  final VoidCallback? onOpenCart;

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _productsAnchor = GlobalKey(
    debugLabel: 'store_products_anchor',
  );
  static const double _nextPageThreshold = 360;
  bool _revealingProducts = false;
  int _revealGeneration = 0;
  int _storeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadNextPage);
    unawaited(context.read<StoreMenuCubit>().load());
  }

  @override
  void didUpdateWidget(covariant StoreDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store.id.toLowerCase() != widget.store.id.toLowerCase()) {
      _storeGeneration++;
      _revealGeneration++;
      _revealingProducts = false;
      unawaited(context.read<StoreMenuCubit>().changeStore(widget.store.id));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _maybeLoadNextPage() {
    if (_revealingProducts ||
        !_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions ||
        _scrollController.position.userScrollDirection !=
            ScrollDirection.reverse ||
        _scrollController.position.extentAfter > _nextPageThreshold) return;
    unawaited(context.read<StoreMenuCubit>().loadNextPage());
  }

  void _revealProducts() {
    final generation = ++_revealGeneration;
    _revealingProducts = true;
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _revealGeneration) return;
      final target = _productsAnchor.currentContext;
      if (target == null || !_scrollController.hasClients) {
        _revealingProducts = false;
        return;
      }
      final media = MediaQuery.of(context);
      final reduceMotion =
          media.disableAnimations || media.accessibleNavigation;
      unawaited(
        Scrollable.ensureVisible(
          target,
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        ).whenComplete(() {
          if (mounted && generation == _revealGeneration) {
            _revealingProducts = false;
          }
        }),
      );
    });
  }

  /// Opens the product sheet and, when the person confirms, adds the chosen
  /// configuration to the cart.
  Future<void> _openItem(MenuItem item) async {
    FocusScope.of(context).unfocus();
    final generation = _storeGeneration;
    final media = MediaQuery.of(context);
    final selection = await showModalBottomSheet<MenuItemSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 760),
      sheetAnimationStyle: media.disableAnimations || media.accessibleNavigation
          ? AnimationStyle.noAnimation
          : null,
      builder: (_) => MenuItemDetailsSheet(item: item),
    );
    if (!mounted || generation != _storeGeneration || selection == null) return;
    await _addToCart(
      item,
      selection.optionId,
      selection.addonIds,
      quantity: selection.quantity,
    );
  }

  /// Quick add from the row: plain products go straight into the cart,
  /// products with choices open the sheet first.
  Future<void> _quickAdd(MenuItem item) async {
    if (item.options.isNotEmpty || item.addons.isNotEmpty) {
      await _openItem(item);
      return;
    }
    await _addToCart(item, null, const <String>{});
  }

  Future<void> _addToCart(
    MenuItem item,
    String? optionId,
    Set<String> addonIds, {
    int quantity = 1,
  }) async {
    final cart = context.read<CartCubit>();
    final result = await cart.add(
      menuItemId: item.id,
      menuItemOptionId: optionId,
      addonIds: addonIds.toList(growable: false),
      quantity: quantity,
    );
    // `busy` = this tap was merged into an add already on its way.
    if (!mounted || result == CartMutationResult.busy) return;
    final copy = AppLocalizations.of(context).cart;
    final message = result == CartMutationResult.success
        ? copy.added
        : result == CartMutationResult.storeConflict
            ? copy.storeConflict
            : cart.state.items.isNotEmpty
                ? copy.addFailedWithCart
                : copy.actionFailed;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openFilters() {
    final cubit = context.read<StoreMenuCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider<StoreMenuCubit>.value(
        value: cubit,
        child: const MenuFiltersSheet(),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).common.comingSoon)),
      );
  }

  @override
  void dispose() {
    _revealGeneration++;
    _scrollController.removeListener(_maybeLoadNextPage);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Scaffold(
      backgroundColor: colors.background,
      // Sits directly above the shell's navigation bar.
      bottomNavigationBar: CartBar(onTap: widget.onOpenCart),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: BlocListener<StoreMenuCubit, StoreMenuState>(
            listenWhen: (before, after) =>
                before.filters.menuCategoryId != after.filters.menuCategoryId,
            listener: (_, __) => _revealProducts(),
            child: CustomScrollView(
              key: const PageStorageKey('store_details_scroll'),
              controller: _scrollController,
              slivers: [
                // Keep the exact passed Store snapshot; no header refetch.
                SliverToBoxAdapter(
                  child: StoreDetailsHeader(
                    store: widget.store,
                    onFavorite: _showComingSoon,
                    onShare: _showComingSoon,
                  ),
                ),
                // Marker just above the pinned chips, so revealing it puts the
                // first product right under them.
                SliverToBoxAdapter(child: SizedBox(key: _productsAnchor)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: MenuCategoryTabsDelegate(
                    onOpenFilters: _openFilters,
                    topInset: MediaQuery.paddingOf(context).top,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                MenuItemResultsSliver(
                  onItemTap: _openItem,
                  onAddTap: _quickAdd,
                ),
                const MenuItemPaginationSliver(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
