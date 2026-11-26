import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_state.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_categories.dart';

import '../../support/main_category_fixtures.dart';

void main() {
  Future<void> pumpCategories(
    WidgetTester tester,
    HomeCategories categories, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    bool settle = true,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: SingleChildScrollView(child: categories)),
    ));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  for (final locale in <Locale>[const Locale('ar'), const Locale('en')]) {
    testWidgets(
        'uses the inherited ${locale.languageCode} locale for category names',
        (tester) async {
      await pumpCategories(
        tester,
        HomeCategories(
          categories: [homeCategory(nameAr: 'مشويات', nameEn: 'Grills')],
        ),
        locale: locale,
      );

      expect(
        find.text(locale.languageCode == 'ar' ? 'مشويات' : 'Grills'),
        findsOneWidget,
      );
      expect(
        find.text(locale.languageCode == 'ar' ? 'Grills' : 'مشويات'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'localizes the ${locale.languageCode} loading, error and empty states',
        (tester) async {
      final copy = AppLocalizations(locale).home;
      await pumpCategories(
        tester,
        const HomeCategories(
          categories: [],
          status: HomeCategoriesStatus.loading,
        ),
        locale: locale,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .semanticsLabel,
        copy.categoriesLoading,
      );
      expect(find.text(copy.categoriesEmpty), findsNothing);

      var retries = 0;
      await pumpCategories(
        tester,
        HomeCategories(
          categories: const [],
          status: HomeCategoriesStatus.error,
          onRetry: () => retries++,
        ),
        locale: locale,
      );
      expect(find.text(copy.categoriesLoadFailed), findsOneWidget);
      expect(find.text(copy.categoriesEmpty), findsNothing);
      await tester.tap(find.byKey(const Key('home_categories_retry')));
      expect(retries, 1);

      await pumpCategories(
        tester,
        const HomeCategories(
          categories: [],
          status: HomeCategoriesStatus.empty,
        ),
        locale: locale,
      );
      expect(find.text(copy.categoriesEmpty), findsOneWidget);
      expect(
        find.byKey(const PageStorageKey('home_categories_rail')),
        findsNothing,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'initial state shows progress rather than a misleading empty state',
      (tester) async {
    await pumpCategories(
      tester,
      const HomeCategories(
        categories: [],
        status: HomeCategoriesStatus.initial,
      ),
      settle: false,
    );
    expect(find.byKey(const Key('home_categories_loading')), findsOneWidget);
    expect(find.byKey(const Key('home_categories_empty')), findsNothing);
  });

  testWidgets('uses the local icon fallback for unmatched category names',
      (tester) async {
    for (final iconUrl in <String?>[
      null,
      '',
      '   ',
      'not a URL',
      '/icons/category.png',
      'ftp://example.test/category.png',
      'javascript:alert(1)',
      'https:///category.png',
      'https://example.test/bad image.png',
      'https://[invalid',
    ]) {
      await pumpCategories(
        tester,
        HomeCategories(
          categories: [
            homeCategory(
              nameAr: 'فئة غير معروفة',
              nameEn: 'Unknown category',
              iconUrl: iconUrl,
            ),
          ],
        ),
      );
      expect(find.byType(Image), findsNothing, reason: 'Invalid URL: $iconUrl');
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'maps supported Arabic and English category names to bundled assets',
      (tester) async {
    const categories = <HomeCategory>[
      HomeCategory(
        id: 'pharmacy',
        nameAr: 'صيدلية',
        nameEn: 'Pharmacy',
        iconUrl: 'https://example.test/pharmacy.png',
        displayOrder: 1,
        isActive: true,
      ),
      HomeCategory(
        id: 'drinks',
        nameAr: 'مشروبات',
        nameEn: 'Drinks',
        iconUrl: null,
        displayOrder: 2,
        isActive: true,
      ),
      HomeCategory(
        id: 'vegetables',
        nameAr: 'خضروات',
        nameEn: 'Vegetables',
        iconUrl: null,
        displayOrder: 3,
        isActive: true,
      ),
      HomeCategory(
        id: 'dessert',
        nameAr: 'حلويات',
        nameEn: 'Dessert',
        iconUrl: null,
        displayOrder: 4,
        isActive: true,
      ),
      HomeCategory(
        id: 'food',
        nameAr: 'مأكولات',
        nameEn: 'Food',
        iconUrl: null,
        displayOrder: 5,
        isActive: true,
      ),
    ];

    await pumpCategories(
      tester,
      const HomeCategories(categories: categories),
    );

    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(5));
    expect(
      images.map((image) => (image.image as AssetImage).assetName),
      containsAll(<String>[
        'assets/category_icons/pharmacy.png',
        'assets/category_icons/drinks.png',
        'assets/category_icons/vegetables.png',
        'assets/category_icons/dessert.png',
        'assets/category_icons/food.png',
      ]),
    );
    expect(images.every((image) => image.fit == BoxFit.contain), isTrue);
    expect(images.every((image) => image.excludeFromSemantics), isTrue);
    expect(find.byIcon(Icons.restaurant_menu), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a semantic tile surface in both light and dark themes',
      (tester) async {
    for (final theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
      await pumpCategories(
        tester,
        HomeCategories(categories: [homeCategory(id: 'restaurants')]),
        theme: theme,
      );

      final card = tester.widget<Card>(
        find.byKey(const Key('category_card_${mainCategoryId}')),
      );
      final colors = theme.extension<AppSemanticColors>()!;
      expect(card.color, colors.card);

      final iconTile = tester.widget<Container>(
        find.byKey(const Key('category_icon_background_${mainCategoryId}')),
      );
      expect(
        (iconTile.decoration! as BoxDecoration).color,
        colors.elevatedSurface,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
