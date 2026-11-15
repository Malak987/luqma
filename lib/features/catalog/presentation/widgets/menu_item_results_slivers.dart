import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_section_feedback.dart';
import '../../../cart/domain/entities/cart_line.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../domain/entities/menu_item.dart';
import '../cubit/store_menu_cubit.dart';
import '../cubit/store_menu_state.dart';
import 'menu_item_card.dart';
import 'pagination_footer.dart';

class MenuItemResultsSliver extends StatefulWidget {
  const MenuItemResultsSliver(
      {required this.onItemTap, required this.onAddTap, super.key});

  /// Opens the product sheet.
  final ValueChanged<MenuItem> onItemTap;

  /// Quick "Add" on a row: adds directly, or opens the sheet when the product
  /// has options or addons to choose from.
  final ValueChanged<MenuItem> onAddTap;
  @override
  State<MenuItemResultsSliver> createState() => _MenuItemResultsSliverState();
}

class _MenuItemResultsSliverState extends State<MenuItemResultsSliver> {
  // Keep lazy child widget identities when appending, not just their keys.
  // Each live tile selects only its own indexed entity. Unchanged cards do not
  // rebuild for footer changes, metadata updates or another product's update.
  final Map<String, Widget> _tiles = {};
  void _openItem(MenuItem item) => widget.onItemTap(item);
  void _addItem(MenuItem item) => widget.onAddTap(item);

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<StoreMenuCubit, StoreMenuState>(
        buildWhen: (before, after) =>
            before.products.status != after.products.status ||
            !identical(before.products.items, after.products.items) ||
            before.products.failure != after.products.failure,
        builder: (context, state) {
          final products = state.products;
          final copy = AppLocalizations.of(context).catalog;
          final colors = Theme.of(context).extension<AppSemanticColors>() ??
              AppSemanticColors.light;
          _tiles.removeWhere((id, _) => !products.byId.containsKey(id));
          final loading = products.status == MenuStatus.loading ||
              products.status == MenuStatus.initial;
          if (loading ||
              products.status == MenuStatus.empty ||
              products.status == MenuStatus.failure) {
            return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverToBoxAdapter(
                    child: AppSectionFeedback(
                        key: Key(loading
                            ? 'menu_products_loading'
                            : products.status == MenuStatus.failure
                                ? 'menu_products_error'
                                : 'menu_products_empty'),
                        icon: products.status == MenuStatus.failure
                            ? Icons.cloud_off_outlined
                            : Icons.restaurant_menu,
                        loading: loading,
                        message: loading
                            ? copy.loadingProducts
                            : products.status == MenuStatus.failure
                                ? copy.productsFailed
                                : copy.productsEmpty,
                        action: products.status == MenuStatus.failure
                            ? TextButton(
                                key: const Key('menu_products_retry'),
                                style: TextButton.styleFrom(
                                    foregroundColor: colors.link),
                                onPressed: context
                                    .read<StoreMenuCubit>()
                                    .retryProducts,
                                child: Text(copy.retry))
                            : null)));
          }
          final indices = <String, int>{
            for (var i = 0; i < products.items.length; i++)
              'menu_item_${products.items[i].id.toLowerCase()}': i
          };
          return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                final id = products.items[index].id.toLowerCase();
                return _tiles.putIfAbsent(
                    id,
                    () => Padding(
                        key: ValueKey('menu_item_$id'),
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _MenuItemTile(
                            itemId: id, onTap: _openItem, onAdd: _addItem)));
              },
                      childCount: products.items.length,
                      findChildIndexCallback: (key) => key is ValueKey<String>
                          ? indices[key.value]
                          : null)));
        },
      );
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile(
      {required this.itemId, required this.onTap, required this.onAdd});
  final String itemId;
  final ValueChanged<MenuItem> onTap;
  final ValueChanged<MenuItem> onAdd;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<StoreMenuCubit, StoreMenuState, MenuItem?>(
        selector: (state) => state.products.byId[itemId],
        builder: (context, item) {
          if (item == null) return const SizedBox.shrink();
          // Items with options/addons can sit in the cart in several
          // configurations, so only plain items get an in-row stepper.
          final customizable =
              item.options.isNotEmpty || item.addons.isNotEmpty;
          final lineKey = CartLine.keyFor(item.id, null, const <String>{});
          return BlocSelector<CartCubit, CartState, int>(
            selector: (cart) => customizable ? 0 : cart.quantityOf(lineKey),
            builder: (context, quantity) => MenuItemCard(
              item: item,
              quantity: quantity,
              onTap: () => onTap(item),
              onAdd: item.isActive ? () => onAdd(item) : null,
              onIncrement: () => context.read<CartCubit>().increment(lineKey),
              onDecrement: () => context.read<CartCubit>().decrement(lineKey),
            ),
          );
        },
      );
}

class MenuItemPaginationSliver extends StatelessWidget {
  const MenuItemPaginationSliver({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<StoreMenuCubit, StoreMenuState, (bool, bool, bool)>(
        selector: (state) => (
          state.products.loadingMore,
          state.products.nextPageFailure != null,
          state.products.status == MenuStatus.success &&
              state.products.hasNextPage
        ),
        builder: (context, footer) {
          final copy = AppLocalizations.of(context).catalog;
          return SliverToBoxAdapter(
              child: PaginationFooter(
                  key: const Key('menu_products_pagination'),
                  loading: footer.$1,
                  failed: footer.$2,
                  canLoadMore: footer.$3,
                  failureLabel: copy.productPaginationFailed,
                  loadMoreLabel: copy.loadMoreProducts,
                  onRetry: context.read<StoreMenuCubit>().retryNextPage,
                  onLoadMore: context.read<StoreMenuCubit>().loadNextPage));
        },
      );
}
