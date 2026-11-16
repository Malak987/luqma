import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_line.dart';
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
          expect(find.byKey(const Key('cart_subtotal')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
