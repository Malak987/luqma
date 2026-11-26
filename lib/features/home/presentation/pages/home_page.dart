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
import '../../domain/entities/home_ad_banner.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../utils/home_layout.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_promo_banner.dart';
import '../widgets/home_restaurants_section.dart';

/// The Home tab: header, search, categories, promotion and restaurants.
///
/// The page owns no data logic and no navigation chrome. [HomeCubit] loads what
/// the screen needs; the bottom bar lives in the app shell, and signing out
/// lives in the Account tab.
class HomePage extends StatefulWidget {
  const HomePage({
    this.onBrowseRestaurants,
    this.onOpenFavorites,
    this.onOpenNotifications,
    this.onOpenAddressPicker,
    this.deliveryAddress,
    this.favoritesCount = 0,
    this.hasUnreadNotifications = false,
    this.ads = const <HomeAdBanner>[],
    super.key,
  });

  /// Called by "See all" and the promo call-to-action. The shell uses it to
  /// switch to the restaurants tab, so Home never reaches into navigation.
  final VoidCallback? onBrowseRestaurants;

  /// Called by the favourites button in the header; the shell switches tabs.
  final VoidCallback? onOpenFavorites;

  /// Called by the notifications button. When absent the header still shows the
  /// action and Home reports that the screen is not available yet.
  final VoidCallback? onOpenNotifications;

  /// Opens the delivery-address sheet. The shell owns that flow because it owns
  /// the address cubit, so Home stays free of shell internals.
  final VoidCallback? onOpenAddressPicker;

  /// Localized one-line summary of the selected address, fed by the shell.
  final String? deliveryAddress;

  /// Live favourites count from the shell's `FavoritesCubit`.
  final int favoritesCount;

  /// Whether the notifications action should show its unread dot.
  final bool hasUnreadNotifications;

  /// Active promotional banners. Empty keeps the built-in default banner.
  final List<HomeAdBanner> ads;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
              _buildHomeAppBar(context, state),
              Expanded(child: _bodyFor(context, state)),
            ],
          ),
        );
      },
    );
  }

  /// The header is pure presentation: name, address summary, favourites count
  /// and every tap handler arrive from the shell. No cubit lookup, no fallback
  /// try/catch — a missing callback simply leaves that action inert.
  Widget _buildHomeAppBar(BuildContext context, HomeState state) {
    return HomeAppBar(
      userName: state.userName,
      deliveryAddress: widget.deliveryAddress,
      favoritesCount: widget.favoritesCount,
      hasUnreadNotifications: widget.hasUnreadNotifications,
      onFavoritesPressed: widget.onOpenFavorites,
      onAddressPressed: widget.onOpenAddressPicker,
      onNotificationsPressed: widget.onOpenNotifications ??
          () => _showMessage(
                AppLocalizations.of(context).home.notificationsUnavailable,
              ),
      // The search API does not exist yet, so submitting reports that honestly
      // instead of navigating to an invented screen.
      onSearchSubmitted: (_) => _showMessage(
        AppLocalizations.of(context).home.searchUnavailable,
      ),
    );
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
              constraints: const BoxConstraints(maxWidth: homeContentMaxWidth),
              child: Padding(
                padding: _paddingFor(constraints),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
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
                    HomePromoBanner(
                      tag: home.promoTag,
                      title: home.promoTitle,
                      highlight: home.promoHighlight,
                      subtitle: home.promoSubtitle,
                      ctaLabel: home.promoCta,
                      onCtaPressed: widget.onBrowseRestaurants,
                      ads: widget.ads,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    HomeRestaurantsSection(
                      restaurants: state.restaurants,
                      status: state.restaurantsStatus,
                      onRetry: context.read<HomeCubit>().retryRestaurants,
                      onStoreTap: (_) => widget.onBrowseRestaurants?.call(),
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

  /// Responsive page padding. The horizontal value comes from the same helper
  /// the header uses, so the search field and the sections share one edge.
  EdgeInsets _paddingFor(BoxConstraints constraints) {
    return EdgeInsets.symmetric(
      horizontal: homeHorizontalPadding(constraints.maxWidth),
      vertical: AppSpacing.lg,
    );
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
