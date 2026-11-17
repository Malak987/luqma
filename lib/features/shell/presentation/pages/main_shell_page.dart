import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../favorites/presentation/cubit/favorites_state.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../restaurants/presentation/pages/restaurants_tab.dart';
import '../cubit/main_shell_cubit.dart';
import '../cubit/main_shell_state.dart';
import '../widgets/app_bottom_nav_bar.dart';

/// The authenticated app shell. It owns the persistent bottom navigation bar
/// and one navigator per tab, so the bar stays visible on every page: tab
/// roots, the stores of a category, and a store's menu are all pushed inside
/// the tab's own navigator, never over the bar.
///
/// Tabs live in an [IndexedStack]: switching keeps each tab's pages, scroll
/// position and loaded data. Tapping the selected tab again returns to its
/// root page.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<MainShellCubit>(create: (_) => sl<MainShellCubit>()),
        BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()),
        BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()..load()),
        BlocProvider<FavoritesCubit>(
          create: (_) => sl<FavoritesCubit>()..load(),
        ),
      ],
      child: const _MainShellView(),
    );
  }
}

class _MainShellView extends StatefulWidget {
  const _MainShellView();

  @override
  State<_MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<_MainShellView> {
  final Map<MainShellTab, GlobalKey<NavigatorState>> _navigatorKeys =
      <MainShellTab, GlobalKey<NavigatorState>>{
        for (final tab in MainShellTab.values)
          tab: GlobalKey<NavigatorState>(debugLabel: 'shell_${tab.name}'),
      };

  /// Back goes to the previous page of the current tab first, then to Home,
  /// and only then leaves the shell.
  Future<void> _handleBack(MainShellState state) async {
    final navigator = _navigatorKeys[state.tab]?.currentState;
    if (navigator != null && await navigator.maybePop()) return;
    if (!mounted) return;
    if (!state.isHome) {
      context.read<MainShellCubit>().goHome();
      return;
    }
    final root = Navigator.of(context);
    if (root.canPop()) {
      root.pop();
    } else {
      await SystemNavigator.pop();
    }
  }

  void _onTabSelected(MainShellTab tab, MainShellState state) {
    if (tab == state.tab) {
      _navigatorKeys[tab]?.currentState?.popUntil((route) => route.isFirst);
      if (tab == MainShellTab.cart) {
        context.read<CartCubit>().refresh();
      } else if (tab == MainShellTab.favorites) {
        context.read<FavoritesCubit>().refreshIfStale();
      }
      return;
    }
    context.read<MainShellCubit>().selectTab(tab);
    if (tab == MainShellTab.cart) {
      context.read<CartCubit>().refresh();
    } else if (tab == MainShellTab.favorites) {
      context.read<FavoritesCubit>().refreshIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final cubit = context.read<MainShellCubit>();

    return BlocBuilder<MainShellCubit, MainShellState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack(state);
          },
          child: Scaffold(
            backgroundColor: colors.background,
            body: IndexedStack(
              index: state.index,
              children: <Widget>[
                _TabNavigator(
                  navigatorKey: _navigatorKeys[MainShellTab.home]!,
                  root: HomePage(
                    onBrowseRestaurants: () =>
                        cubit.selectTab(MainShellTab.restaurants),
                  ),
                ),
                _TabNavigator(
                  navigatorKey: _navigatorKeys[MainShellTab.restaurants]!,
                  root: const RestaurantsTab(),
                ),
                _TabNavigator(
                  navigatorKey: _navigatorKeys[MainShellTab.cart]!,
                  root: const CartPage(),
                ),
                _TabNavigator(
                  navigatorKey: _navigatorKeys[MainShellTab.favorites]!,
                  root: const FavoritesPage(),
                ),
                _TabNavigator(
                  navigatorKey: _navigatorKeys[MainShellTab.account]!,
                  root: const AccountPage(),
                ),
              ],
            ),
            bottomNavigationBar: BlocSelector<CartCubit, CartState, int>(
              selector: (cart) => cart.badgeQuantity,
              builder: (context, cartCount) =>
                  BlocSelector<FavoritesCubit, FavoritesState, int>(
                selector: (favorites) => favorites.badgeCount,
                builder: (context, favoritesCount) => AppBottomNavBar(
                  currentTab: state.tab,
                  onSelected: (tab) => _onTabSelected(tab, state),
                  items: <AppNavItem>[
                    AppNavItem(
                      tab: MainShellTab.home,
                      icon: Icons.home_rounded,
                      label: l10n.navigation.home,
                    ),
                    AppNavItem(
                      tab: MainShellTab.restaurants,
                      icon: Icons.storefront_rounded,
                      label: l10n.navigation.restaurants,
                    ),
                    AppNavItem(
                      tab: MainShellTab.cart,
                      icon: Icons.shopping_cart_outlined,
                      label: l10n.navigation.cart,
                      badgeCount: cartCount,
                    ),
                    AppNavItem(
                      tab: MainShellTab.favorites,
                      icon: Icons.favorite_border_rounded,
                      label: l10n.navigation.favorites,
                      badgeCount: favoritesCount,
                    ),
                    AppNavItem(
                      tab: MainShellTab.account,
                      icon: Icons.person_outline_rounded,
                      label: l10n.navigation.account,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One tab's own [Navigator]. Its first page is [root]; every other named
/// route goes through the app router, so existing `AppRouter.pushNamed` calls
/// keep working and now open inside the tab, under the navigation bar.
class _TabNavigator extends StatelessWidget {
  const _TabNavigator({required this.navigatorKey, required this.root});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;

  @override
  Widget build(BuildContext context) {
    // Several navigators must not share the app's single HeroController.
    return HeroControllerScope.none(
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) {
          if (settings.name == Navigator.defaultRouteName) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => root,
            );
          }
          return AppRouter.onGenerateRoute(settings);
        },
      ),
    );
  }
}
