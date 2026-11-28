import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/cart/presentation/widgets/cart_checkout_panel.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets('summary fits narrow large-text screen $locale dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 600));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          theme: dark ? AppTheme.dark : AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
              body: Align(
                  alignment: Alignment.bottomCenter,
                  child: CartCheckoutPanel(
                    subTotal: 12345.67,
                    canCheckout: true,
                    onApplyPromo: (_) {},
                    onCheckout: () {},
                  ))),
        ));
        await tester.pump();
        expect(find.byKey(const Key('cart_subtotal')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
