import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_line.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/catalog/domain/entities/menu_item.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_details_page.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_details_sheet.dart';

import '../../../cart/support/cart_fixtures.dart';
import '../../support/menu_fixtures.dart';

void main() {
  testWidgets('configurable item opens details instead of adding immediately',
      (tester) async {
    final menuRepo = FakeMenuRepository()
      ..onItems = (_) async => menuPage(items: [
            menuItem(options: const [
              MenuItemOption(
                  id: optionId, nameAr: 'عادي', nameEn: 'Regular', price: 10)
            ])
          ]);
    final cartRepo = FakeCartRepository();
    final cart = CartCubit(
      addToCartUseCase: AddToCartUseCase(cartRepo),
      updateToCartUseCase: UpdateToCartUseCase(cartRepo),
      clearCartUseCase: ClearCartUseCase(cartRepo),
      getMyCartUseCase: GetMyCartUseCase(cartRepo),
    );
    final menu = StoreMenuCubit(
      storeId: storeId,
      getCategories: GetActiveMenuCategoriesUseCase(menuRepo),
      getItems: GetMenuItemsUseCase(menuRepo),
      paging: const CatalogPaging(),
    );
    addTearDown(() async {
      await cart.close();
      await menu.close();
    });
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>.value(value: cart),
        BlocProvider<StoreMenuCubit>.value(value: menu)
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoreDetailsPage(store: store()),
      ),
    ));
    await tester.pumpAndSettle();
    final add = find.byKey(Key('menu_add_$menuItemId'));
    await tester.scrollUntilVisible(add, 200,
        scrollable: find
            .descendant(
                of: find.byKey(const PageStorageKey('store_details_scroll')),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemDetailsSheet), findsOneWidget);
    expect(cartRepo.lastAdd, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('plain-item add shows pending feedback from CartCubit',
      (tester) async {
    final response = Completer<CartLine>();
    final menuRepo = FakeMenuRepository()
      ..onItems = (_) async => menuPage(items: [menuItem()]);
    final cartRepo = FakeCartRepository()..onAdd = (_) => response.future;
    final cart = CartCubit(
      addToCartUseCase: AddToCartUseCase(cartRepo),
      updateToCartUseCase: UpdateToCartUseCase(cartRepo),
      clearCartUseCase: ClearCartUseCase(cartRepo),
      getMyCartUseCase: GetMyCartUseCase(cartRepo),
    );
    await cart.load();
    final menu = StoreMenuCubit(
      storeId: storeId,
      getCategories: GetActiveMenuCategoriesUseCase(menuRepo),
      getItems: GetMenuItemsUseCase(menuRepo),
      paging: const CatalogPaging(),
    );
    addTearDown(() async {
      await cart.close();
      await menu.close();
    });
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>.value(value: cart),
        BlocProvider<StoreMenuCubit>.value(value: menu)
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoreDetailsPage(store: store()),
      ),
    ));
    await tester.pumpAndSettle();
    final add = find.byKey(Key('menu_add_$menuItemId'));
    await tester.scrollUntilVisible(add, 200,
        scrollable: find
            .descendant(
                of: find.byKey(const PageStorageKey('store_details_scroll')),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(add);
    await tester.pump();
    expect(
        find.descendant(
            of: add, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget);
    expect(cartRepo.lastAdd?.menuItemId, menuItemId);
    response.complete(
        cartLine(menuItemId: menuItemId, menuItemOptionId: null, quantity: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'rejected add preserves existing cart and gives contextual guidance',
      (tester) async {
    final existing = cartLine(quantity: 2);
    final repo = FakeCartRepository()
      ..currentCart = cart(items: [existing])
      ..onAdd = (_) async =>
          throw const FailureException(Failure(FailureCode.validation));
    final cartCubit = CartCubit(
      addToCartUseCase: AddToCartUseCase(repo),
      updateToCartUseCase: UpdateToCartUseCase(repo),
      clearCartUseCase: ClearCartUseCase(repo),
      getMyCartUseCase: GetMyCartUseCase(repo),
    );
    await cartCubit.load();
    final menuRepo = FakeMenuRepository()
      ..onItems = (_) async => menuPage(items: [menuItem()]);
    final menuCubit = StoreMenuCubit(
        storeId: storeId,
        getCategories: GetActiveMenuCategoriesUseCase(menuRepo),
        getItems: GetMenuItemsUseCase(menuRepo),
        paging: const CatalogPaging());
    addTearDown(() async {
      await cartCubit.close();
      await menuCubit.close();
    });
    await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cartCubit),
          BlocProvider<StoreMenuCubit>.value(value: menuCubit)
        ],
        child: MaterialApp(
            locale: const Locale('en'),
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StoreDetailsPage(store: store()))));
    await tester.pumpAndSettle();
    final add = find.byKey(Key('menu_add_$menuItemId'));
    await tester.scrollUntilVisible(add, 200,
        scrollable: find
            .descendant(
                of: find.byKey(const PageStorageKey('store_details_scroll')),
                matching: find.byType(Scrollable))
            .first);
    await tester.drag(find.byKey(const PageStorageKey('store_details_scroll')),
        const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
        find.text(AppLocalizations(const Locale('en')).cart.addFailedWithCart),
        findsOneWidget);
    expect(cartCubit.state.items, [existing]);
    expect(repo.clearCalls, 0);
    expect(tester.takeException(), isNull);
  });
}
