import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/data/models/menu_item_model.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_card.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_details_sheet.dart';
import '../../support/menu_fixtures.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    for (final dark in [false, true]) {
      for (final image in [null, 'not a valid image url']) {
        testWidgets(
            'null comparison and $image artwork: card and details $locale dark=$dark',
            (tester) async {
          final json = menuItemJson()
            ..['compareAtPrice'] = null
            ..['imageUrl'] = image;
          final item = MenuItemModel.fromJson(json).toDomain();
          final copy = AppLocalizations(locale).catalog;
          Widget app(Widget child) => MaterialApp(
                locale: locale,
                theme: dark ? AppTheme.dark : AppTheme.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(body: child),
              );
          expect(item.hasSale, isFalse);
          expect(item.discountPercent, 0);
          expect(item.price, 25.5);
          await tester.pumpWidget(app(MenuItemCard(
              item: item,
              onTap: () {},
              onAdd: () {},
              onIncrement: () {},
              onDecrement: () {})));
          await tester.pumpAndSettle();
          expect(find.byType(MenuArtworkPlaceholder), findsOneWidget);
          expect(find.text(copy.money(25.5)), findsOneWidget);
          expect(find.text(copy.sale), findsNothing);
          expect(find.text(copy.discountPercent(0)), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(app(MenuItemDetailsSheet(item: item)));
          await tester.pumpAndSettle();
          expect(find.byType(MenuArtworkPlaceholder), findsOneWidget);
          expect(find.text(copy.money(25.5)), findsWidgets);
          expect(find.text(copy.sale), findsNothing);
          expect(find.text(copy.discountPercent(0)), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
