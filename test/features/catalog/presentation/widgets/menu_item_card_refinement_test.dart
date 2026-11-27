import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_card.dart';

import '../../support/menu_fixtures.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets('card fits 320px and large text in $locale dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final item = menuItem(
          nameAr: 'اسم منتج عربي طويل جدا لاختبار حجم الخط والاتجاه في الشاشة',
          nameEn: 'A very long product name for testing narrow mobile layouts',
          price: 25.5,
          compare: 30,
        );
        final copy = AppLocalizations(locale).catalog;
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          theme: dark ? AppTheme.dark : AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: MenuItemCard(
            item: item,
            onTap: () {},
            onAdd: () {},
            onIncrement: () {},
            onDecrement: () {},
            quantity: 1,
          ))),
        ));
        await tester.pump();
        expect(find.byKey(Key('menu_stepper_${item.id}')), findsOneWidget);
        expect(find.byType(MenuArtworkPlaceholder), findsOneWidget);
        expect(find.text(copy.money(item.price)), findsOneWidget);
        expect(find.text(copy.discountPercent(item.discountPercent)),
            findsNothing);
        expect(find.text(copy.sale), findsNothing);
        expect(
            Directionality.of(tester.element(find.byType(MenuItemCard))),
            locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('add, pending and stepper use existing callbacks',
      (tester) async {
    var adds = 0;
    var plus = 0;
    var minus = 0;
    final item = menuItem();
    Widget card(
            {int quantity = 0, bool adding = false, bool readOnly = false}) =>
        MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: MenuItemCard(
            item: item,
            onTap: () {},
            onAdd: () => adds++,
            onIncrement: () => plus++,
            onDecrement: () => minus++,
            quantity: quantity,
            isAdding: adding,
            readOnlyLine: readOnly,
          ))),
        );
    await tester.pumpWidget(card());
    await tester.tap(find.byKey(Key('menu_add_${item.id}')));
    expect(adds, 1);
    await tester.pumpWidget(card(adding: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(card(quantity: 1));
    await tester.pump();
    final copy = AppLocalizations(const Locale('en')).cart;
    await tester.tap(find.byTooltip(copy.increase));
    await tester.tap(find.byTooltip(copy.remove));
    expect(plus, 1);
    expect(minus, 1);
    final switcher = tester.widget<AnimatedSwitcher>(
      find
          .descendant(
              of: find.byType(MenuItemCard),
              matching: find.byType(AnimatedSwitcher))
          .last,
    );
    expect(switcher.duration, Duration.zero);
    await tester.pumpWidget(card(quantity: 1, readOnly: true));
    await tester.pump();
    expect(find.byKey(Key('menu_readonly_${item.id}')), findsOneWidget);
    expect(find.byKey(Key('menu_stepper_${item.id}')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
