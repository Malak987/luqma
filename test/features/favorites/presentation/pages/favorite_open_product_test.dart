import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/features/catalog/domain/entities/menu_item.dart';
import 'package:luqma_app/features/catalog/domain/usecases/find_menu_item_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/favorites/domain/queries/favorite_paging.dart';
import 'package:luqma_app/features/favorites/domain/usecases/add_to_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/remove_from_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/get_my_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:luqma_app/features/favorites/presentation/pages/favorites_page.dart';
import '../../../catalog/support/menu_fixtures.dart';
import '../../../cart/support/cart_fixtures.dart';
import '../../support/favorite_fixtures.dart';

void main() {
  testWidgets(
      'favorite opens actual product choices without adding until confirmed',
      (tester) async {
    final product = menuItem(id: favoriteMenuItemId, addons: [
      const MenuItemAddon(
          id: addonId, nameAr: 'جبنة', nameEn: 'Cheese', price: 4),
    ]);
    final catalog = FakeMenuRepository()
      ..onItems = (_) async => menuPage(items: [product]);
    sl.registerSingleton<FindMenuItemUseCase>(FindMenuItemUseCase(catalog));
    addTearDown(() => sl.unregister<FindMenuItemUseCase>());
    final cartRepo = FakeCartRepository();
    final cart = CartCubit(
        addToCartUseCase: AddToCartUseCase(cartRepo),
        updateToCartUseCase: UpdateToCartUseCase(cartRepo),
        clearCartUseCase: ClearCartUseCase(cartRepo),
        getMyCartUseCase: GetMyCartUseCase(cartRepo));
    final favRepo = FakeFavoritesRepository();
    final favorites = FavoritesCubit(
        addToFavoritesUseCase: AddToFavoritesUseCase(favRepo),
        removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(favRepo),
        getMyFavoritesUseCase: GetMyFavoritesUseCase(favRepo),
        paging: const FavoritePaging(),
        repository: favRepo,
        getAuthenticatedUserId: () async => 'test');
    addTearDown(cart.close);
    addTearDown(favorites.close);
    await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cart),
          BlocProvider<FavoritesCubit>.value(value: favorites),
        ],
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
                body: FavoriteMenuItemCard(
                    item: favoriteItem(imageUrl: null))))));
    await tester.tap(find.text('Nile dish'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Cheese'), findsOneWidget);
    expect(find.byKey(const Key('menu_add_to_cart')), findsOneWidget);
    expect(cartRepo.lastUpdate, isNull);
    expect(catalog.queries, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
