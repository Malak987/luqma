import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:luqma_app/features/cart/presentation/pages/cart_page.dart';
import '../../support/cart_fixtures.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets(
          'cart feedback and retries fit narrow view $locale dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var retries = 0;
        final copy = AppLocalizations(locale).cart;
        Widget app(CartState state) => MaterialApp(
              locale: locale,
              theme: dark ? AppTheme.dark : AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(2),
                      disableAnimations: true),
                  child: child!),
              home: Scaffold(
                  body: CartPageContent(
                      state: state,
                      onRetry: () async => retries++,
                      onBrowseRestaurants: () {})),
            );
        await tester.pumpWidget(app(const CartState(status: CartStatus.error)));
        await tester.ensureVisible(find.byKey(const Key('cart_retry_button')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('cart_retry_button')));
        await tester.pump();
        expect(retries, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(app(CartState(
            status: CartStatus.empty,
            cart: cart(),
            isSynchronizationFailure: true)));
        await tester.pump();
        expect(find.text(copy.synchronizationFailed), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byTooltip(copy.retry));
        await tester.tap(find.byTooltip(copy.retry));
        await tester.pump();
        expect(retries, 2);
        expect(tester.takeException(), isNull);
      });
      testWidgets(
          'stale server prices stay hidden until reconciled $locale dark=$dark',
          (tester) async {
        final copy = AppLocalizations(locale).cart;
        final snapshot = cart(items: [cartLine()]).copyWith(subTotal: 540);
        Widget app(bool stale) => MaterialApp(
              locale: locale,
              theme: dark ? AppTheme.dark : AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                  body: CartPageContent(
                      state: CartState(
                          status: CartStatus.populated,
                          cart: snapshot,
                          pricesAreStale: stale),
                      onRetry: () async {})),
            );
        await tester.pumpWidget(app(true));
        final total = find.byKey(const Key('cart_subtotal'));
        await tester.ensureVisible(total);
        expect(tester.widget<Text>(total).data, copy.pricesPending);
        await tester.pumpWidget(app(false));
        expect(tester.widget<Text>(total).data, copy.amount(540));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
