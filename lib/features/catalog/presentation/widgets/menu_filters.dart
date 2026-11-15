import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/store_menu_cubit.dart';
import '../cubit/store_menu_state.dart';

/// Owns and disposes only UI drafts/controllers/debounce. Query validation and
/// paging reset live in the injected Cubit/use cases, never in the widgets.
class MenuProductFilters extends StatefulWidget {
  const MenuProductFilters({super.key});
  @override
  State<MenuProductFilters> createState() => _MenuProductFiltersState();
}

class _MenuProductFiltersState extends State<MenuProductFilters> {
  late final TextEditingController _search;
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;
  Timer? _debounce;
  late String _storeId;
  num? _appliedMin;
  num? _appliedMax;
  bool _priceError = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<StoreMenuCubit>().state;
    _storeId = state.storeId;
    final filters = state.filters;
    _appliedMin = filters.minPrice;
    _appliedMax = filters.maxPrice;
    _search = TextEditingController(text: filters.search ?? '');
    _minimum = TextEditingController(text: filters.minPrice?.toString() ?? '');
    _maximum = TextEditingController(text: filters.maxPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  void _searchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) unawaited(context.read<StoreMenuCubit>().search(text));
    });
  }

  void _submitSearch(String text) {
    _debounce?.cancel();
    unawaited(context.read<StoreMenuCubit>().search(text));
  }

  // Arabic/Persian digits and the Arabic decimal separator are accepted without
  // guessing grouping/currency conventions or transmitting localized strings.
  double? _price(String raw) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var value = raw.trim().replaceAll('٫', '.');
    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
    }
    return double.tryParse(value);
  }

  void _applyPrices() {
    final minText = _minimum.text.trim();
    final maxText = _maximum.text.trim();
    final min = _price(minText);
    final max = _price(maxText);
    final invalid =
        (minText.isNotEmpty && (min == null || !min.isFinite || min < 0)) ||
            (maxText.isNotEmpty && (max == null || !max.isFinite || max < 0)) ||
            (min != null && max != null && min > max);
    setState(() => _priceError = invalid);
    if (!invalid)
      unawaited(context.read<StoreMenuCubit>().setPriceRange(min, max));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = l10n.catalog;
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return BlocListener<StoreMenuCubit, StoreMenuState>(
      listenWhen: (before, after) =>
          before.storeId != after.storeId ||
          before.filters.search != after.filters.search ||
          before.filters.minPrice != after.filters.minPrice ||
          before.filters.maxPrice != after.filters.maxPrice,
      listener: (context, state) {
        final changedStore = _storeId != state.storeId;
        _storeId = state.storeId;
        if (changedStore) _debounce?.cancel();
        final text = state.filters.search ?? '';
        if (changedStore || _search.text.trim() != text) {
          _debounce?.cancel();
          _search.text = text;
        }
        final min = state.filters.minPrice;
        final max = state.filters.maxPrice;
        final changedPrice = _appliedMin != min || _appliedMax != max;
        if (changedStore || _appliedMin != min)
          _minimum.text = min?.toString() ?? '';
        if (changedStore || _appliedMax != max)
          _maximum.text = max?.toString() ?? '';
        _appliedMin = min;
        _appliedMax = max;
        if (_priceError && (changedStore || changedPrice))
          setState(() => _priceError = false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppTextField(
            key: const Key('menu_search'),
            controller: _search,
            hintText: copy.searchProducts,
            semanticLabel: copy.searchProducts,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
                key: const Key('menu_search_clear'),
                tooltip: copy.clearSearch,
                onPressed: () {
                  _search.clear();
                  _submitSearch('');
                },
                icon: const Icon(Icons.close)),
            textInputAction: TextInputAction.search,
            onChanged: _searchChanged,
            onSubmitted: _submitSearch,
          ),
          ExpansionTile(
            key: const PageStorageKey('menu_product_filters'),
            maintainState: true,
            tilePadding: EdgeInsets.zero,
            title: Text(copy.productFilters),
            leading: Icon(Icons.tune, color: colors.link),
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final minimum = AppTextField(
                    key: const Key('menu_min_price'),
                    controller: _minimum,
                    labelText: copy.minPrice,
                    semanticLabel: copy.minPrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next);
                final maximum = AppTextField(
                    key: const Key('menu_max_price'),
                    controller: _maximum,
                    labelText: copy.maxPrice,
                    semanticLabel: copy.maxPrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _applyPrices());
                if (constraints.maxWidth < AppSizes.mediumWidth ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                  return Column(children: [
                    minimum,
                    const SizedBox(height: AppSpacing.sm),
                    maximum
                  ]);
                }
                return Row(children: [
                  Expanded(child: minimum),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: maximum)
                ]);
              }),
              if (_priceError)
                Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Semantics(
                        liveRegion: true,
                        child: Text(copy.invalidPrices,
                            key: const Key('menu_price_error'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.error)))),
              TextButton(
                  key: const Key('menu_apply_prices'),
                  style: TextButton.styleFrom(foregroundColor: colors.link),
                  onPressed: _applyPrices,
                  child: Text(copy.applyPrices)),
              BlocSelector<StoreMenuCubit, StoreMenuState, bool>(
                  selector: (state) => state.filters.saleOnly,
                  builder: (context, value) => SwitchListTile.adaptive(
                      key: const Key('menu_sale_only'),
                      contentPadding: EdgeInsets.zero,
                      value: value,
                      title: Text(copy.saleOnly),
                      onChanged: context.read<StoreMenuCubit>().setSaleOnly)),
            ],
          ),
        ]),
      ),
    );
  }
}

/// Bottom sheet that hosts the product search and price filters. It needs the
/// [StoreMenuCubit] above it (the page passes it with `BlocProvider.value`).
class MenuFiltersSheet extends StatelessWidget {
  const MenuFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context).catalog;
    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(copy.productFilters,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              const MenuProductFilters(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: AppButton(
                  key: const Key('menu_filters_done'),
                  text: copy.done,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
