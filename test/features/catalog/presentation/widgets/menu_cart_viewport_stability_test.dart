import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_line.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_details_page.dart';
import '../../../cart/support/cart_fixtures.dart';
import '../../support/menu_fixtures.dart';

void main() {
  testWidgets('first pending add does not resize the menu viewport',
      (tester) async {
    final pending = Completer<CartLine>();
    final repo = FakeCartRepository()..onAdd = (_) => pending.future;
    final cartCubit = CartCubit(
        addToCartUseCase: AddToCartUseCase(repo),
        updateToCartUseCase: UpdateToCartUseCase(repo),
        clearCartUseCase: ClearCartUseCase(repo),
        getMyCartUseCase: GetMyCartUseCase(repo));
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
    await cartCubit.load();
    await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cartCubit),
          BlocProvider.value(value: menuCubit)
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StoreDetailsPage(store: store()),
        )));
    await tester.pumpAndSettle();
    final scroll = find.byKey(const PageStorageKey('store_details_scroll'));
    final before = tester.getSize(scroll);
    final add = find.byKey(Key('menu_add_$menuItemId'));
    await tester.scrollUntilVisible(add, 200,
        scrollable: find
            .descendant(of: scroll, matching: find.byType(Scrollable))
            .first);
    await tester.tap(add);
    await tester.pump();
    expect(find.byKey(const Key('cart_bar')), findsOneWidget);
    expect(tester.getSize(scroll), before);
    pending.complete(
        cartLine(menuItemId: menuItemId, menuItemOptionId: null, quantity: 1));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
