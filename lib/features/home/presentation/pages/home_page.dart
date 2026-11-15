import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/catalog_route_arguments.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../address/presentation/cubit/address_setup_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_promo_banner.dart';
import '../widgets/home_restaurants_section.dart';
import '../widgets/home_search_bar.dart';

/// The Home tab: header, search, promo, categories and restaurants.
///
/// The page owns no data logic and no navigation chrome. [HomeCubit] loads what
/// the screen needs; the bottom bar lives in the app shell, and signing out
/// lives in the Account tab.
class HomePage extends StatefulWidget {
  const HomePage({this.onBrowseRestaurants, super.key});

  /// Called by "See all" and the promo call-to-action. The shell uses it to
  /// switch to the restaurants tab, so Home never reaches into navigation.
  final VoidCallback? onBrowseRestaurants;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Widest the home column grows on tablets, desktop and web.
  static const double _contentMaxWidth = 1120;
  static const double _errorActionWidth = 220;

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          body: Column(
            children: <Widget>[
              HomeAppBar(
                userName: state.userName,
                deliveryAddress: _deliveryAddress(context),
                onNotificationsPressed: () =>
                    _showMessage(AppLocalizations.of(context)
                        .home
                        .notificationsUnavailable),
              ),
              Expanded(child: _bodyFor(context, state)),
            ],
          ),
        );
      },
    );
  }

  /// Reads the selected address from the AddressSetupCubit that the address
  /// gate provides. Null when the gate is not in the tree (e.g. tests).
  String? _deliveryAddress(BuildContext context) {
    try {
      final addressState = context.watch<AddressSetupCubit>().state;
      if (addressState.isPopulated && addressState.addresses.isNotEmpty) {
        final a = addressState.addresses.first;
        return '${a.district}, ${a.city}';
      }
    } catch (_) {
      // Address gate not in tree.
    }
    return null;
  }

  Widget _bodyFor(BuildContext context, HomeState state) {
    switch (state.status) {
      case HomeStatus.initial:
      case HomeStatus.loading:
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case HomeStatus.failure:
        return _buildErrorView(context);
      case HomeStatus.loaded:
        return _buildContent(context, state);
    }
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    final home = AppLocalizations.of(context).home;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Padding(
                padding: _paddingFor(constraints),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    HomeSearchBar(
                      hintText: home.searchHint,
                      onSubmitted: (_) =>
                          _showMessage(home.searchUnavailable),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HomePromoBanner(
                      tag: home.promoTag,
                      title: home.promoTitle,
                      discount: home.promoDiscount,
                      subtitle: home.promoSubtitle,
                      ctaLabel: home.promoCta,
                      onCtaPressed: widget.onBrowseRestaurants,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    HomeCategories(
                      categories: state.categories,
                      status: state.categoriesStatus,
                      onRetry: context.read<HomeCubit>().retryCategories,
                      onCategoryTap: (category) {
                        AppRouter.pushNamed<void>(
                          context,
                          AppRoutes.storeDiscovery,
                          arguments: StoreDiscoveryArguments(
                            mainCategoryId: category.id,
                            nameAr: category.nameAr,
                            nameEn: category.nameEn,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    HomeRestaurantsSection(
                      restaurants: state.restaurants,
                      onSeeAll: widget.onBrowseRestaurants,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: AppSizes.iconLarge,
              color: colors.mutedText,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.home.loadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: _errorActionWidth,
              child: AppButton(text: l10n.home.retry, onPressed: _retry),
            ),
          ],
        ),
      ),
    );
  }

  /// Responsive page padding, mirroring the breakpoints the auth shell uses.
  EdgeInsets _paddingFor(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final horizontal = width < AppSizes.compactWidth
        ? AppSpacing.md
        : width < AppSizes.mediumWidth
            ? AppSpacing.xl
            : AppSpacing.xxl;

    return EdgeInsets.symmetric(
        horizontal: horizontal, vertical: AppSpacing.lg);
  }

  void _retry() {
    context.read<HomeCubit>().load();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
