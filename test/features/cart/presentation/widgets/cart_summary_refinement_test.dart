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
      testWidgets('summary uses server subtotal at 320px $locale dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final copy = AppLocalizations(locale).cart;
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          theme: dark ? AppTheme.dark : AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
              body: CartPageContent(
            state: CartState(
                status: CartStatus.populated,
                cart: cart(items: [cartLine()]).copyWith(subTotal: 540)),
            onRetry: () async {},
          )),
        ));
        final total = find.byKey(const Key('cart_subtotal'));
        await tester.scrollUntilVisible(total, 200,
            scrollable: find.byType(Scrollable).first);
        expect(find.text(copy.orderSummary), findsOneWidget);
        expect(find.text(copy.amount(540)), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
