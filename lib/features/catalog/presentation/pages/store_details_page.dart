import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../address/presentation/cubit/address_setup_cubit.dart';
import '../../../address/presentation/cubit/address_setup_state.dart';
import '../../domain/repositories/store_details_repository.dart';
import '../../../cart/presentation/widgets/cart_bar.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/store.dart';
import '../cubit/store_menu_cubit.dart';
import '../cubit/store_details_cubit.dart';
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
  Timer? _categoryRefreshTimer;
  StreamSubscription<AddressSetupState>? _addressSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadNextPage);
    final addressCubit = context.read<AddressSetupCubit?>();
    final details = context.read<StoreDetailsCubit?>();
    if (addressCubit != null && details != null) {
      _addressSubscription = addressCubit.stream.listen((state) {
        // A transient loading/error state with no list does not mean the
        // selected address was actually removed.
        if (state.addresses.isEmpty &&
            (state.status == AddressSetupStatus.loading ||
                state.status == AddressSetupStatus.error ||
                state.status == AddressSetupStatus.initial)) return;
        final address = state.selectedAddress;
        final location = address == null
            ? null
            : StoreDetailsLocation(address.latitude, address.longitude);
        unawaited(details.changeLocation(location));
      });
    }
    unawaited(context.read<StoreMenuCubit>().load());
    _categoryRefreshTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (!mounted ||
          (WidgetsBinding.instance.lifecycleState != null &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed) ||
          ModalRoute.of(context)?.isCurrent == false ||
          !TickerMode.of(context)) return;
      unawaited(context.read<StoreMenuCubit>().refreshCategoriesSilently());
    });
  }

  @override
  void didUpdateWidget(covariant StoreDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store.id.toLowerCase() != widget.store.id.toLowerCase()) {
      _storeGeneration++;
      _revealGeneration++;
      _revealingProducts = false;
      unawaited(context.read<StoreMenuCubit>().changeStore(widget.store.id));
      final details = context.read<StoreDetailsCubit?>();
      if (details != null) unawaited(details.changeStore(widget.store));
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
      builder: (_) {
        final details = context.read<StoreDetailsCubit?>();
        final sheet = MenuItemDetailsSheet(item: item);
        return details == null
            ? sheet
            : BlocProvider<StoreDetailsCubit>.value(
                value: details, child: sheet);
      },
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
      builder: (_) {
        final details = context.read<StoreDetailsCubit?>();
        final sheet = BlocProvider<StoreMenuCubit>.value(
            value: cubit, child: const MenuFiltersSheet());
        return details == null
            ? sheet
            : BlocProvider<StoreDetailsCubit>.value(
                value: details, child: sheet);
      },
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
    _categoryRefreshTimer?.cancel();
    _addressSubscription?.cancel();
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
      // Overlay the summary instead of resizing the menu viewport when the
      // first item is added. A trailing sliver keeps the last row reachable.
      body: Stack(children: [
        Align(
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
                  SliverToBoxAdapter(
                    child: _DetailsHeader(
                      fallback: widget.store,
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
                  const SliverToBoxAdapter(child: _MenuCacheNotice()),
                  MenuItemResultsSliver(
                    onItemTap: _openItem,
                    onAddTap: _quickAdd,
                  ),
                  const MenuItemPaginationSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: 104)),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: CartBar(onTap: widget.onOpenCart),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader(
      {required this.fallback,
      required this.onFavorite,
      required this.onShare});
  final Store fallback;
  final VoidCallback onFavorite, onShare;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StoreDetailsCubit?>();
    if (cubit == null)
      return StoreDetailsHeader(
          store: fallback, onFavorite: onFavorite, onShare: onShare);
    return BlocBuilder<StoreDetailsCubit, StoreDetailsState>(
      bloc: cubit,
      builder: (context, state) {
        final ar = AppLocalizations.of(context).locale.languageCode == 'ar';
        final colors = Theme.of(context).extension<AppSemanticColors>() ??
            AppSemanticColors.light;
        return Column(children: [
          StoreDetailsHeader(
              store: state.store, onFavorite: onFavorite, onShare: onShare),
          if (state.stale)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Expanded(
                    child: Text(
                        state.failed
                            ? (ar
                                ? 'تعذر تحديث بيانات المطعم؛ المعروض قديم.'
                                : 'Could not refresh store details; shown data may be outdated.')
                            : (ar
                                ? 'جارٍ تحديث بيانات المطعم'
                                : 'Refreshing store details'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.mutedText))),
                if (state.failed)
                  TextButton(
                      onPressed: () => cubit.load(force: true),
                      child: Text(AppLocalizations.of(context).catalog.retry)),
              ]),
            ),
        ]);
      },
    );
  }
}

class _MenuCacheNotice extends StatelessWidget {
  const _MenuCacheNotice();
  @override
  Widget build(BuildContext context) => BlocBuilder<StoreMenuCubit,
          StoreMenuState>(
      buildWhen: (a, b) =>
          a.categories.stale != b.categories.stale ||
          a.categories.failure != b.categories.failure ||
          a.products.stale != b.products.stale ||
          a.products.failure != b.products.failure,
      builder: (context, state) {
        if (!state.categories.stale && !state.products.stale)
          return const SizedBox.shrink();
        final ar = AppLocalizations.of(context).locale.languageCode == 'ar';
        final failed =
            state.categories.failure != null || state.products.failure != null;
        final colors = Theme.of(context).extension<AppSemanticColors>() ??
            AppSemanticColors.light;
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Expanded(
                  child: Text(
                      failed
                          ? (ar
                              ? 'تعذر تحديث القائمة؛ قد تكون البيانات المعروضة قديمة.'
                              : 'Could not refresh the menu; shown data may be outdated.')
                          : (ar
                              ? 'جارٍ تحديث بيانات القائمة'
                              : 'Refreshing menu data'),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.mutedText))),
              if (failed)
                TextButton(
                    onPressed: () {
                      final cubit = context.read<StoreMenuCubit>();
                      if (state.categories.failure != null)
                        cubit.retryCategories();
                      if (state.products.failure != null) cubit.retryProducts();
                    },
                    child: Text(AppLocalizations.of(context).catalog.retry)),
            ]));
      });
}
