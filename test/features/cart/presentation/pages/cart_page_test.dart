import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_line.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_cart_count_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:luqma_app/features/cart/presentation/pages/cart_page.dart';

import '../../support/cart_fixtures.dart';

void main() {
  Widget host(Widget child, {required Locale locale, required bool dark}) {
    return MaterialApp(
      locale: locale,
      theme: dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders empty, loading and error cart states', (tester) async {
    Future<void> retry() async {}
    await tester.pumpWidget(
      host(
        CartPageContent(
          state: const CartState(status: CartStatus.loading),
          onRetry: retry,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    expect(find.byKey(const Key('cart_loading_state')), findsOneWidget);

    await tester.pumpWidget(
      host(
        CartPageContent(
          state: const CartState(status: CartStatus.empty),
          onRetry: retry,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    expect(find.byKey(const Key('cart_empty_state')), findsOneWidget);

    await tester.pumpWidget(
      host(
        CartPageContent(
          state: const CartState(status: CartStatus.error),
          onRetry: retry,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    expect(find.byKey(const Key('cart_error_state')), findsOneWidget);
    expect(find.byKey(const Key('cart_retry_button')), findsOneWidget);
  });

  testWidgets('quantity-one minus is enabled and requests zero removal',
      (tester) async {
    int? requestedQuantity;
    await tester.pumpWidget(
      host(
        CartLineTile(
          line: cartLine(quantity: 1),
          isMutating: false,
          isClearing: false,
          isCartPending: false,
          pendingMessage: 'Syncing cart',
          onQuantityChanged: (delta) => requestedQuantity = delta,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    final decrease = find.byWidgetPredicate(
      (widget) =>
          widget is IconButton && widget.tooltip == 'Remove item from cart',
    );
    expect(decrease, findsOneWidget);
    expect(tester.widget<IconButton>(decrease).onPressed, isNotNull);
    await tester.tap(decrease);
    expect(requestedQuantity, -1);
  });

  testWidgets(
      'failed zero removal preserves the line and shows localized feedback',
      (tester) async {
    final line = cartLine(quantity: 1);
    final repository = FakeCartRepository()
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 1)
      ..onUpdate = (_) async => throw const FailureException(
            Failure(FailureCode.network),
          );
    final cubit = CartCubit(
      addToCartUseCase: AddToCartUseCase(repository),
      updateToCartUseCase: UpdateToCartUseCase(repository),
      clearCartUseCase: ClearCartUseCase(repository),
      getMyCartUseCase: GetMyCartUseCase(repository),
      getCartCountUseCase: GetCartCountUseCase(repository),
    );
    addTearDown(cubit.close);
    await cubit.load();
    const locale = Locale('ar');
    final copy = AppLocalizations(locale).cart;

    await tester.pumpWidget(
      host(
        BlocProvider<CartCubit>.value(value: cubit, child: const CartPage()),
        locale: locale,
        dark: false,
      ),
    );
    await tester.tap(find.byTooltip(copy.remove));
    await tester.pumpAndSettle();

    expect(find.text(copy.actionFailed), findsOneWidget);
    expect(cubit.state.items, <CartLine>[line]);
    expect(cubit.state.badgeQuantity, 1);
  });

  testWidgets('Clear Cart asks confirmation before invoking the mutation',
      (tester) async {
    var clearCalls = 0;
    Future<void> retry() async {}
    Future<CartMutationResult> clear() async {
      clearCalls++;
      return CartMutationResult.success;
    }
    await tester.pumpWidget(
      host(
        CartPageContent(
          state: CartState(
            status: CartStatus.populated,
            cart: cart(items: [cartLine()]),
            count: cartCount(linesCount: 1, totalQuantity: 2),
          ),
          onRetry: retry,
          onClearCart: clear,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    await tester.tap(find.byKey(const Key('cart_clear_button')));
    await tester.pumpAndSettle();
    expect(clearCalls, 0);
    await tester.tap(find.byKey(const Key('cart_clear_confirm_button')));
    await tester.pumpAndSettle();
    expect(clearCalls, 1);
  });

  testWidgets('unavailable line enables decrease but not increase',
      (tester) async {
    final copy = AppLocalizations(const Locale('en')).cart;
    final line = cartLine(quantity: 2, available: false);
    await tester.pumpWidget(
      host(
        CartLineTile(
          line: line,
          isMutating: false,
          isClearing: false,
          isCartPending: false,
          pendingMessage: 'Updating cart',
          onQuantityChanged: (_) {},
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    final decrease = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == copy.decrease,
    );
    final increase = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == copy.increase,
    );
    expect(tester.widget<IconButton>(decrease).onPressed, isNotNull);
    expect(tester.widget<IconButton>(increase).onPressed, isNull);
    expect(find.text(copy.unavailable), findsOneWidget);
  });

  testWidgets('increase is disabled at the documented 99 maximum',
      (tester) async {
    final copy = AppLocalizations(const Locale('en')).cart;
    await tester.pumpWidget(
      host(
        CartLineTile(
          line: cartLine(quantity: 99),
          isMutating: false,
          isClearing: false,
          isCartPending: false,
          pendingMessage: 'Updating cart',
          onQuantityChanged: (_) {},
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    final decrease = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == copy.decrease,
    );
    final increase = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == copy.increase,
    );
    expect(tester.widget<IconButton>(decrease).onPressed, isNotNull);
    expect(tester.widget<IconButton>(increase).onPressed, isNull);
  });

  testWidgets('a mutation in flight shows updating copy, not syncing copy',
      (tester) async {
    Future<void> retry() async {}
    final line = cartLine(quantity: 2);
    await tester.pumpWidget(
      host(
        CartPageContent(
          state: CartState(
            status: CartStatus.populated,
            cart: cart(items: <CartLine>[line]),
            count: cartCount(linesCount: 1, totalQuantity: 2),
            mutatingLineKeys: const <String>{'in-flight'},
          ),
          onRetry: retry,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    expect(find.text('Updating cart'), findsWidgets);
    expect(find.text('Syncing cart'), findsNothing);

    await tester.pumpWidget(
      host(
        CartPageContent(
          state: CartState(
            status: CartStatus.populated,
            cart: cart(items: <CartLine>[line]),
            count: cartCount(linesCount: 1, totalQuantity: 2),
            isSynchronizing: true,
          ),
          onRetry: retry,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    expect(find.text('Syncing cart'), findsWidgets);
  });

  for (final locale in <Locale>[const Locale('ar'), const Locale('en')]) {
    for (final dark in <bool>[false, true]) {
      testWidgets(
        'cart line is responsive and localized in ${locale.languageCode} ${dark ? 'dark' : 'light'}',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          Future<void> retry() async {}
          final line = cartLine(
            addons: const <CartLineAddon>[
              CartLineAddon(
                id: cartAddonId,
                nameAr: 'إضافة أرز',
                nameEn: 'Extra Rice',
                price: 20,
              ),
            ],
          );
          await tester.pumpWidget(
            host(
              MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: CartPageContent(
                  state: CartState(
                    status: CartStatus.populated,
                    cart: cart(items: <CartLine>[line]),
                    count: cartCount(linesCount: 1, totalQuantity: 2),
                  ),
                  onRetry: retry,
                ),
              ),
              locale: locale,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(Key('cart_line_$cartLineId')), findsOneWidget);
          expect(
            find.text(locale.languageCode == 'ar' ? line.nameAr : line.nameEn),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.byKey(const Key('cart_subtotal')),
            100,
            scrollable: find.descendant(
              of: find.byKey(const Key('cart_populated_state')),
              matching: find.byType(Scrollable),
            ),
          );
          expect(find.byKey(const Key('cart_subtotal')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
