import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_section_feedback.dart';
import '../../../catalog/presentation/cubit/store_discovery_cubit.dart';
import '../../../catalog/presentation/widgets/store_discovery_view.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../../domain/restaurant_category_resolver.dart';

/// Root of the Restaurants tab.
///
/// It reuses the category list Home already loads (through [HomeCubit]) to find
/// the restaurants category, then shows the shared store browsing screen for
/// it. All catalog logic stays in the catalog feature.
class RestaurantsTab extends StatelessWidget {
  const RestaurantsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).catalog;
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (before, after) =>
          before.categoriesStatus != after.categoriesStatus ||
          before.categories != after.categories,
      builder: (context, state) {
        switch (state.categoriesStatus) {
          case HomeCategoriesStatus.initial:
          case HomeCategoriesStatus.loading:
            return _TabMessage(
              loading: true,
              icon: Icons.storefront_outlined,
              message: copy.loadingStores,
            );
          case HomeCategoriesStatus.error:
            return _TabMessage(
              icon: Icons.cloud_off_outlined,
              message: copy.restaurantsUnavailable,
              action: TextButton(
                key: const Key('restaurants_retry'),
                onPressed: context.read<HomeCubit>().retryCategories,
                child: Text(copy.retry),
              ),
            );
          case HomeCategoriesStatus.empty:
          case HomeCategoriesStatus.success:
            final category =
                RestaurantCategoryResolver.resolve(state.categories);
            if (category == null) {
              return _TabMessage(
                icon: Icons.storefront_outlined,
                message: copy.storesEmpty,
              );
            }
            return BlocProvider<StoreDiscoveryCubit>(
              // A different category means a different store list.
              key: ValueKey<String>(category.id),
              create: (_) =>
                  sl<StoreDiscoveryCubit>(param1: category.id),
              child: StoreDiscoveryView(
                title: copy.restaurants,
                searchHint: copy.searchRestaurants,
                sectionTitle: copy.suggestedRestaurants,
                sectionHint: copy.suggestedRestaurantsHint,
              ),
            );
        }
      },
    );
  }
}

class _TabMessage extends StatelessWidget {
  const _TabMessage({
    required this.icon,
    required this.message,
    this.action,
    this.loading = false,
  });

  final IconData icon;
  final String message;
  final Widget? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppSectionFeedback(
              icon: icon,
              message: message,
              loading: loading,
              action: action,
            ),
          ),
        ),
      ),
    );
  }
}
