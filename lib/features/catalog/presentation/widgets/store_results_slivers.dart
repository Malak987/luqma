import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_section_feedback.dart';
import '../../domain/entities/store.dart';
import '../cubit/store_discovery_cubit.dart';
import '../cubit/store_discovery_state.dart';
import 'pagination_footer.dart';
import 'store_card.dart';

/// A lazy vertical sliver. Footer-only changes retain the same immutable items
/// reference and do not rebuild this subtree (or the independent selectors).
class StoreResultsSliver extends StatelessWidget {
  const StoreResultsSliver({required this.onStoreTap, super.key});
  final ValueChanged<Store> onStoreTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreDiscoveryCubit, StoreDiscoveryState>(
      buildWhen: (previous, current) =>
          previous.stores.status != current.stores.status ||
          !identical(previous.stores.items, current.stores.items) ||
          previous.stores.failure != current.stores.failure ||
          previous.searchQuery != current.searchQuery,
      builder: (context, state) {
        final stores = state.stores;
        final copy = AppLocalizations.of(context).catalog;
        final colors = Theme.of(context).extension<AppSemanticColors>() ??
            AppSemanticColors.light;
        final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
        final loading = stores.status == CatalogStatus.initial ||
            stores.status == CatalogStatus.loading;
        if (loading ||
            stores.status == CatalogStatus.empty ||
            stores.status == CatalogStatus.failure) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
                child: AppSectionFeedback(
              key: Key(loading
                  ? 'stores_loading'
                  : stores.status == CatalogStatus.failure
                      ? 'stores_error'
                      : 'stores_empty'),
              icon: stores.status == CatalogStatus.failure
                  ? Icons.cloud_off_outlined
                  : Icons.storefront_outlined,
              loading: loading,
              message: loading
                  ? copy.loadingStores
                  : stores.status == CatalogStatus.failure
                      ? copy.storesFailed
                      : copy.storesEmpty,
              action: stores.status == CatalogStatus.failure
                  ? TextButton(
                      key: const Key('stores_retry'),
                      style: TextButton.styleFrom(foregroundColor: colors.link),
                      onPressed:
                          context.read<StoreDiscoveryCubit>().retryStores,
                      child: Text(copy.retry),
                    )
                  : null,
            )),
          );
        }
        final visible = state.visibleStores;
        if (visible.isEmpty) {
          // Stores did load, but none of them matches the search text. More
          // pages may still match; the pagination footer offers to load them.
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
                child: AppSectionFeedback(
              key: const Key('stores_search_empty'),
              icon: Icons.search_off_rounded,
              message: copy.noSearchResults,
            )),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
            (context, index) {
              final store = visible[index];
              return Padding(
                key: ValueKey('store_${store.id.toLowerCase()}'),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: StoreCard(
                  name: arabic ? store.nameAr : store.nameEn,
                  imageUrl: store.iconUrl,
                  address: store.address,
                  categoryName:
                      arabic ? store.mainCategoryNameAr : store.mainCategoryNameEn,
                  isOpenNow: store.isOpenNow,
                  onTap: () => onStoreTap(store),
                ),
              );
            },
            childCount: visible.length,
          )),
        );
      },
    );
  }
}

class StorePaginationSliver extends StatelessWidget {
  const StorePaginationSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StoreDiscoveryCubit, StoreDiscoveryState,
        (bool, bool, bool)>(
      selector: (state) => (
        state.stores.isLoadingMore,
        state.stores.nextPageFailure != null,
        state.stores.status == CatalogStatus.success && state.stores.hasNextPage
      ),
      builder: (context, selection) => SliverToBoxAdapter(
        child: PaginationFooter(
          key: const Key('stores_pagination'),
          loading: selection.$1,
          failed: selection.$2,
          canLoadMore: selection.$3,
          onRetry: context.read<StoreDiscoveryCubit>().retryNextPage,
          onLoadMore: context.read<StoreDiscoveryCubit>().loadNextPage,
        ),
      ),
    );
  }
}
