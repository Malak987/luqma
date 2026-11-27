import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_line.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_update_result.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:luqma_app/features/cart/presentation/pages/cart_page.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:luqma_app/features/favorites/presentation/pages/favorites_page.dart';
import '../../support/cart_fixtures.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets('empty cart and favorites browse action $locale dark=$dark',
          (tester) async {
        var browses = 0;
        Future<void> noop() async {}
        Widget app(Widget child) => MaterialApp(
              locale: locale,
              theme: dark ? AppTheme.dark : AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: child),
            );
        await tester.pumpWidget(app(CartPageContent(
          state: const CartState(status: CartStatus.empty),
          onRetry: noop,
          onBrowseRestaurants: () => browses++,
        )));
        await tester.tap(find.byKey(const Key('cart_browse_restaurants')));
        await tester.pumpWidget(app(FavoritesPageContent(
          state: const FavoritesState(status: FavoritesStatus.empty),
          onRetry: noop,
          onLoadMore: noop,
          onRetryMore: noop,
          onBrowseRestaurants: () => browses++,
        )));
        await tester.tap(find.byKey(const Key('favorites_browse_restaurants')));
        expect(browses, 2);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('remove targets one exact configuration and preserves the other',
      (tester) async {
    final first = cartLine(quantity: 2, addons: const [
      CartLineAddon(id: cartAddonId, nameAr: 'أرز', nameEn: 'Rice', price: 5),
    ]);
    final second = cartLine(
        id: otherCartLineId, menuItemOptionId: otherCartOptionId, quantity: 3);
    final waiting = Completer<CartUpdateResult>();
    final repo = FakeCartRepository()
      ..currentCart = cart(items: [first, second])
      ..onUpdate = (_) => waiting.future;
    final cubit = CartCubit(
        addToCartUseCase: AddToCartUseCase(repo),
        updateToCartUseCase: UpdateToCartUseCase(repo),
        clearCartUseCase: ClearCartUseCase(repo),
        getMyCartUseCase: GetMyCartUseCase(repo));
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<CartCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CartPage(),
        )));
    await tester.tap(find.byKey(Key('cart_remove_${first.id}')));
    await tester.pumpAndSettle();
    expect(repo.lastUpdate, isNull);
    await tester.tap(find.byKey(const Key('cart_remove_confirm')));
    await tester.pump();
    expect(repo.lastUpdate?.menuItemId, first.menuItemId);
    expect(repo.lastUpdate?.menuItemOptionId, first.menuItemOptionId);
    expect(repo.lastUpdate?.addonIds, [cartAddonId]);
    expect(repo.lastUpdate?.quantity, 0);
    expect(cubit.state.items.any((line) => line.id == second.id), isTrue);
    waiting.complete(const CartUpdateResult(isRemoved: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(cubit.state.items.map((line) => line.id), [second.id]);
    expect(repo.clearCalls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('edit quantity preserves a configured line identity',
      (tester) async {
    final first = cartLine(quantity: 2, addons: const [
      CartLineAddon(id: cartAddonId, nameAr: 'أرز', nameEn: 'Rice', price: 5),
    ]);
    final repo = FakeCartRepository()..currentCart = cart(items: [first]);
    final cubit = CartCubit(
        addToCartUseCase: AddToCartUseCase(repo),
        updateToCartUseCase: UpdateToCartUseCase(repo),
        clearCartUseCase: ClearCartUseCase(repo),
        getMyCartUseCase: GetMyCartUseCase(repo));
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<CartCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CartPage(),
        )));
    await tester.tap(find.byKey(Key('cart_edit_${first.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rice'), findsWidgets);
    final modal = find.byType(BottomSheet);
    final increase = find.descendant(
        of: modal,
        matching:
            find.byTooltip(AppLocalizations(const Locale('en')).cart.increase));
    await tester.tap(increase);
    await tester.tap(find.byKey(const Key('cart_edit_save')));
    await tester.pumpAndSettle();
    expect(repo.lastUpdate?.menuItemOptionId, cartOptionId);
    expect(repo.lastUpdate?.addonIds, [cartAddonId]);
    expect(repo.lastUpdate?.quantity, 3);
    expect(repo.clearCalls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'stale editor rejects a recreated line with the same configuration',
      (tester) async {
    final first = cartLine(quantity: 2);
    final repo = FakeCartRepository()..currentCart = cart(items: [first]);
    final cubit = CartCubit(
        addToCartUseCase: AddToCartUseCase(repo),
        updateToCartUseCase: UpdateToCartUseCase(repo),
        clearCartUseCase: ClearCartUseCase(repo),
        getMyCartUseCase: GetMyCartUseCase(repo));
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<CartCubit>.value(
        value: cubit,
        child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CartPage())));
    await tester.tap(find.byKey(Key('cart_edit_${first.id}')));
    await tester.pumpAndSettle();
    final increase = find.descendant(
        of: find.byType(BottomSheet),
        matching:
            find.byTooltip(AppLocalizations(const Locale('en')).cart.increase));
    await tester.tap(increase);
    repo.currentCart =
        cart(items: [cartLine(id: otherCartLineId, quantity: 2)]);
    await cubit.refresh(force: true);
    await tester.pump();
    await tester.tap(find.byKey(const Key('cart_edit_save')));
    await tester.pumpAndSettle();
    expect(repo.lastUpdate, isNull);
    expect(find.text(AppLocalizations(const Locale('en')).cart.lineChanged),
        findsOneWidget);
  });
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets(
          'quantity editor fits 320px with large text $locale dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final line = cartLine(quantity: 2, addons: const [
          CartLineAddon(
              id: cartAddonId,
              nameAr: 'إضافة طويلة لاختبار العربية',
              nameEn: 'A long optional addition',
              price: 5),
        ]);
        final repo = FakeCartRepository()..currentCart = cart(items: [line]);
        final cubit = CartCubit(
            addToCartUseCase: AddToCartUseCase(repo),
            updateToCartUseCase: UpdateToCartUseCase(repo),
            clearCartUseCase: ClearCartUseCase(repo),
            getMyCartUseCase: GetMyCartUseCase(repo));
        await cubit.load();
        addTearDown(cubit.close);
        await tester.pumpWidget(BlocProvider<CartCubit>.value(
            value: cubit,
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      disableAnimations: true),
                  child: child!),
              home: const CartPage(),
            )));
        await tester.pumpAndSettle();
        final edit = find.byKey(Key('cart_edit_${line.id}'));
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        await tester.tap(edit);
        await tester.pumpAndSettle();
        final save = find.byKey(const Key('cart_edit_save'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(save, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
