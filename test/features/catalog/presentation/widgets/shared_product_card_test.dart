import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_card.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/shared_product_card.dart';
import 'package:luqma_app/features/favorites/presentation/pages/favorites_page.dart';
import '../../support/menu_fixtures.dart';
import '../../../favorites/support/favorite_fixtures.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets('catalog and favorite use the same card $locale dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        Widget app(Widget child) => MaterialApp(
              locale: locale,
              theme: dark ? AppTheme.dark : AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SingleChildScrollView(child: child)),
            );
        var opened = false;
        await tester.pumpWidget(app(MenuItemCard(
            item: menuItem(),
            onTap: () => opened = true,
            onAdd: () {},
            onIncrement: () {},
            onDecrement: () {})));
        expect(find.byType(SharedProductCard), findsOneWidget);
        await tester.tap(
            find.text(locale.languageCode == 'ar' ? 'طبق النيل' : 'Nile dish'));
        expect(opened, isTrue);
        await tester
            .pumpWidget(app(FavoriteMenuItemCard(item: favoriteItem())));
        expect(find.byType(SharedProductCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
