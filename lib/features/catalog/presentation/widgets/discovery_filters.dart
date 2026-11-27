import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_circle_icon_button.dart';
import '../../../../core/widgets/app_section_feedback.dart';
import '../../domain/queries/store_filters.dart';
import '../cubit/store_discovery_cubit.dart';
import '../cubit/store_discovery_state.dart';
import 'catalog_choice_selector.dart';
import 'price_range_sheet.dart';

/// Filter row under the search field: the filter sheet button and the quick
/// "open now" toggle. Sort and price filters are missing on purpose: the API
/// exposes neither a rating nor a price level (see BACKEND_MISSING_DATA.md).
class DiscoveryFilterBar extends StatelessWidget {
  const DiscoveryFilterBar({super.key});

  void _openSheet(BuildContext context) {
    final cubit = context.read<StoreDiscoveryCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<StoreDiscoveryCubit>.value(
        value: cubit,
        child: const DiscoveryFilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppCircleIconButton(
            key: const Key('discovery_filters_button'),
            icon: Icons.tune_rounded,
            tooltip: copy.filters,
            backgroundColor: colors.primary,
            iconColor: colors.onPrimary,
            onPressed: () => _openSheet(context),
          ),
          const SizedBox(width: AppSpacing.xs),
          BlocSelector<StoreDiscoveryCubit, StoreDiscoveryState, bool>(
            selector: (state) => state.openNowOnly,
            builder: (context, openNow) => _FilterPill(
              key: const Key('open_now_filter'),
              icon: Icons.schedule_rounded,
              label: copy.openNowFilter,
              selected: openNow,
              onTap: () =>
                  context.read<StoreDiscoveryCubit>().setOpenNowOnly(!openNow),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

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
        color: selected ? colors.primary : colors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? colors.primary : colors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(label,
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Full filter sheet: dining option, categories (cuisines), price range, open
/// now and sort. Edits a local draft; nothing changes until "Apply".
class DiscoveryFilterSheet extends StatefulWidget {
  const DiscoveryFilterSheet({super.key});

  @override
  State<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends State<DiscoveryFilterSheet> {
  static const int _collapsedCategories = 4;

  late String? _cuisineId;
  late bool _openNow;
  late StorePriceRange? _price;
  late StoreSort _sort;
  late StoreOrderMode _mode;
  bool _showAllCategories = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<StoreDiscoveryCubit>().state;
    _cuisineId = state.selectedCuisineId;
    _openNow = state.openNowOnly;
    _price = state.priceRange;
    _sort = state.sort;
    _mode = state.orderMode;
  }

  Future<void> _pickPrice() async {
    final result = await PriceRangeSheet.show(context, initial: _price);
    if (result != null && mounted) setState(() => _price = result);
  }

  void _apply() {
    context.read<StoreDiscoveryCubit>().applyFilters(
          cuisineId: _cuisineId,
          openNowOnly: _openNow,
          priceRange: _price,
          sort: _sort,
          orderMode: _mode,
        );
    Navigator.of(context).maybePop();
  }

  void _clearAll() {
    context.read<StoreDiscoveryCubit>().clearAllFilters();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
    final height = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * .92),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(copy.filters,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: colors.headingText,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: AppSpacing.xs),
                        Text(copy.filterSubtitle,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.mutedText)),
                      ],
                    ),
                  ),
                  AppCircleIconButton(
                    key: const Key('filters_close'),
                    icon: Icons.close_rounded,
                    tooltip: copy.close,
                    backgroundColor: theme.brightness == Brightness.dark
                        ? colors.elevatedSurface
                        : colors.background,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                shrinkWrap: true,
                children: [
                  _SectionLabel(copy.diningOption),
                  _OrderModeSwitch(
                    mode: _mode,
                    deliveryLabel: copy.delivery,
                    pickupLabel: copy.pickup,
                    onChanged: (value) => setState(() => _mode = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(copy.filterCategories),
                  _buildCategories(context, arabic),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(copy.priceRange),
                  _PriceRow(
                    key: const Key('filters_price_row'),
                    range: _price,
                    onTap: _pickPrice,
                    onClear: () => setState(() => _price = null),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile.adaptive(
                    key: const Key('open_now_switch'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: colors.primary,
                    value: _openNow,
                    title: Text(copy.openNowFilter,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: colors.bodyText)),
                    onChanged: (value) => setState(() => _openNow = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel(copy.sortBy),
                  for (final option in <(StoreSort, IconData, String)>[
                    (StoreSort.recommended, Icons.thumb_up_alt_outlined,
                        copy.sortRecommended),
                    (StoreSort.popular, Icons.star_border_rounded,
                        copy.sortPopular),
                    (StoreSort.nearest, Icons.location_on_outlined,
                        copy.sortNearest),
                  ])
                    _SortOption(
                      key: ValueKey('sort_${option.$1.name}'),
                      icon: option.$2,
                      label: option.$3,
                      selected: _sort == option.$1,
                      onTap: () => setState(() => _sort = option.$1),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  children: [
                    TextButton(
                      key: const Key('filters_clear'),
                      style: TextButton.styleFrom(foregroundColor: colors.link),
                      onPressed: _clearAll,
                      child: Text(copy.clearAll,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('filters_done'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _apply,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(copy.applyFilters,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context, bool arabic) {
    final copy = AppLocalizations.of(context).catalog;
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return BlocSelector<StoreDiscoveryCubit, StoreDiscoveryState,
        CuisineSectionState>(
      selector: (state) => state.cuisines,
      builder: (context, cuisines) {
        if (cuisines.status == CatalogStatus.initial ||
            cuisines.status == CatalogStatus.loading) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: LinearProgressIndicator(
                color: colors.primary,
                borderRadius: AppRadius.pillRadius,
                semanticsLabel: copy.loadingCuisines),
          );
        }
        if (cuisines.items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
                cuisines.status == CatalogStatus.failure
                    ? copy.cuisinesFailed
                    : copy.cuisinesEmpty,
                style: Theme.of(context).textTheme.bodySmall),
          );
        }
        final all = cuisines.items;
        final visible = _showAllCategories || all.length <= _collapsedCategories
            ? all
            : all.take(_collapsedCategories).toList(growable: false);
        return Column(
          children: [
            for (var i = 0; i < visible.length; i++)
              _CategoryRow(
                key: ValueKey('filter_cuisine_${visible[i].id}'),
                label: arabic ? visible[i].nameAr : visible[i].nameEn,
                checked: _cuisineId?.toLowerCase() ==
                    visible[i].id.toLowerCase(),
                showDivider: i < visible.length - 1,
                // The stores endpoint takes one cuisine at a time.
                onChanged: (checked) => setState(
                    () => _cuisineId = checked ? visible[i].id : null),
              ),
            if (all.length > _collapsedCategories)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const Key('filters_more_categories'),
                  style: TextButton.styleFrom(foregroundColor: colors.link),
                  onPressed: () => setState(
                      () => _showAllCategories = !_showAllCategories),
                  child: Text(
                      _showAllCategories
                          ? copy.fewerCategories
                          : copy.moreCategories,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(text,
            style: theme.textTheme.titleMedium?.copyWith(
                color: colors.headingText, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _OrderModeSwitch extends StatelessWidget {
  const _OrderModeSwitch({
    required this.mode,
    required this.deliveryLabel,
    required this.pickupLabel,
    required this.onChanged,
  });

  final StoreOrderMode mode;
  final String deliveryLabel;
  final String pickupLabel;
  final ValueChanged<StoreOrderMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    Widget segment(StoreOrderMode value, IconData icon, String label) {
      final selected = mode == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 44,
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 18,
                      color: selected ? colors.onPrimary : colors.mutedText),
                  const SizedBox(width: AppSpacing.xs),
                  Text(label,
                      style: theme.textTheme.labelLarge?.copyWith(
                          color:
                              selected ? colors.onPrimary : colors.mutedText,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colors.background
            : colors.background.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Row(children: [
        segment(StoreOrderMode.delivery, Icons.local_shipping_outlined,
            deliveryLabel),
        segment(StoreOrderMode.pickup, Icons.directions_walk_rounded,
            pickupLabel),
      ]),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    required this.showDivider,
    super.key,
  });

  final String label;
  final bool checked;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.divider))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.bodyText, fontWeight: FontWeight.w600)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                    color: checked ? colors.primary : colors.divider,
                    width: 1.6),
              ),
              child: checked
                  ? Icon(Icons.check_rounded, size: 16, color: colors.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.range,
    required this.onTap,
    required this.onClear,
    super.key,
  });

  final StorePriceRange? range;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    final active = range != null;
    return Material(
      color: active
          ? colors.primary.withValues(alpha: .07)
          : theme.brightness == Brightness.dark
              ? colors.elevatedSurface
              : colors.background.withValues(alpha: .6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: active ? colors.primary : colors.border),
      ),
      child: InkWell(
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.payments_outlined, color: colors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  active
                      ? copy.priceRangeText(range!.min, range!.max)
                      : copy.anyPrice,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: active ? colors.link : colors.bodyText,
                      fontWeight: FontWeight.w700),
                ),
              ),
              if (active)
                IconButton(
                  key: const Key('filters_price_clear'),
                  tooltip: copy.clearFilters,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: colors.mutedText),
                  onPressed: onClear,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.mutedText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected
              ? colors.primary.withValues(alpha: .07)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: selected ? colors.primary.withValues(alpha: .5) : Colors.transparent),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: colors.accent),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(label,
                        style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.bodyText,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600)),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: selected ? colors.primary : colors.divider,
                          width: 2),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuisine chips. Subscribes to cuisine/filter changes only, not to store
/// loading or pagination.
class DiscoveryCuisineFilter extends StatelessWidget {
  const DiscoveryCuisineFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StoreDiscoveryCubit, StoreDiscoveryState,
        (CuisineSectionState, String?)>(
      selector: (state) => (state.cuisines, state.selectedCuisineId),
      builder: (context, selection) {
        final (cuisines, selectedId) = selection;
        final l10n = AppLocalizations.of(context).catalog;
        final arabic = AppLocalizations.of(context).locale.languageCode == 'ar';
        final colors = Theme.of(context).extension<AppSemanticColors>() ??
            AppSemanticColors.light;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CatalogChoiceSelector(
                choices: cuisines.items
                    .map((cuisine) => CatalogChoice(
                          id: cuisine.id,
                          label: arabic ? cuisine.nameAr : cuisine.nameEn,
                          imageUrl: cuisine.imageUrl,
                        ))
                    .toList(growable: false),
                allLabel: l10n.all,
                selectedId: selectedId,
                onSelected: context.read<StoreDiscoveryCubit>().selectCuisine,
              ),
              if (cuisines.status == CatalogStatus.initial ||
                  cuisines.status == CatalogStatus.loading)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: LinearProgressIndicator(
                      color: colors.primary,
                      borderRadius: AppRadius.pillRadius,
                      semanticsLabel: l10n.loadingCuisines),
                ),
              if (cuisines.status == CatalogStatus.failure)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: AppSectionFeedback(
                    key: const Key('cuisines_error'),
                    icon: Icons.cloud_off_outlined,
                    message: l10n.cuisinesFailed,
                    action: TextButton(
                      key: const Key('cuisines_retry'),
                      style: TextButton.styleFrom(foregroundColor: colors.link),
                      onPressed:
                          context.read<StoreDiscoveryCubit>().retryCuisines,
                      child: Text(l10n.retry),
                    ),
                  ),
                ),
              if (cuisines.status == CatalogStatus.empty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(l10n.cuisinesEmpty,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ]);
      },
    );
  }
}

/// "Suggested restaurants" heading. "Show all" appears only while a filter or
/// a search is narrowing the list.
class DiscoverySectionHeader extends StatelessWidget {
  const DiscoverySectionHeader(
      {required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title,
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.headingText,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.mutedText)),
                ]),
          ),
          BlocSelector<StoreDiscoveryCubit, StoreDiscoveryState, bool>(
            selector: (state) =>
                state.hasActiveFilters || state.searchQuery.isNotEmpty,
            builder: (context, active) => active
                ? TextButton(
                    key: const Key('discovery_show_all'),
                    onPressed: context.read<StoreDiscoveryCubit>().clearAllFilters,
                    child: Text(copy.showAll),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
