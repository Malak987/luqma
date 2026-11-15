import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/store_menu_cubit.dart';
import '../cubit/store_menu_state.dart';

/// Pins the menu category chips under the status bar while the menu scrolls.
///
/// [topInset] is the status bar height: the pinned header grows by it so the
/// chips never sit under the system clock. While the header is not pinned the
/// extra band simply shows the page background.
class MenuCategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  const MenuCategoryTabsDelegate({
    required this.onOpenFilters,
    required this.topInset,
  });

  static const double barHeight = 64;

  final VoidCallback onOpenFilters;
  final double topInset;

  @override
  double get minExtent => barHeight + topInset;

  @override
  double get maxExtent => barHeight + topInset;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return ColoredBox(
      color: overlapsContent ? colors.surface : colors.background,
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: MenuCategoryTabs(onOpenFilters: onOpenFilters),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant MenuCategoryTabsDelegate oldDelegate) =>
      oldDelegate.onOpenFilters != onOpenFilters ||
      oldDelegate.topInset != topInset;
}

/// "All" plus one chip per menu category, and the filters button. Loading and
/// failure of the categories never hide the products below.
class MenuCategoryTabs extends StatelessWidget {
  const MenuCategoryTabs({required this.onOpenFilters, super.key});

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final l10n = AppLocalizations.of(context);
    final copy = l10n.catalog;
    final arabic = l10n.locale.languageCode == 'ar';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: SizedBox(
        height: MenuCategoryTabsDelegate.barHeight,
        child: Row(
          children: [
            Expanded(
              child: BlocSelector<StoreMenuCubit, StoreMenuState,
                  (MenuCategoryState, String?)>(
                selector: (state) =>
                    (state.categories, state.filters.menuCategoryId),
                builder: (context, selection) {
                  final (categories, selectedId) = selection;
                  final cubit = context.read<StoreMenuCubit>();
                  final loading = categories.status == MenuStatus.initial ||
                      categories.status == MenuStatus.loading;
                  final failed = categories.status == MenuStatus.failure;
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ListView(
                        key: const PageStorageKey('menu_category_tabs'),
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        children: [
                          _TabPill(
                            key: const ValueKey('menu_category_all'),
                            label: copy.allCategories,
                            selected: selectedId == null,
                            onTap: () => cubit.selectCategory(null),
                          ),
                          for (final category in categories.items) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _TabPill(
                              key: ValueKey('menu_category_${category.id}'),
                              label:
                                  arabic ? category.nameAr : category.nameEn,
                              selected: category.id.toLowerCase() ==
                                  selectedId?.toLowerCase(),
                              onTap: () => cubit.selectCategory(category.id),
                            ),
                          ],
                          if (failed) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _TabPill(
                              key: const Key('menu_categories_retry'),
                              label: copy.retry,
                              icon: Icons.refresh_rounded,
                              selected: false,
                              onTap: cubit.retryCategories,
                            ),
                          ],
                        ],
                      ),
                      if (loading)
                        LinearProgressIndicator(
                          minHeight: 2,
                          color: colors.primary,
                          backgroundColor: Colors.transparent,
                          semanticsLabel: copy.loadingMenuCategories,
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: IconButton(
                key: const Key('menu_filters_button'),
                tooltip: copy.productFilters,
                icon: Icon(Icons.tune_rounded, color: colors.primary),
                onPressed: onOpenFilters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final foreground = selected ? colors.onPrimary : colors.bodyText;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primary : colors.background,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? colors.primary : colors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Text(label,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}
