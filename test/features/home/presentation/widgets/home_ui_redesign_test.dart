import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_radius.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_state.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_categories.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_restaurants_section.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_search_bar.dart';

import '../../support/main_category_fixtures.dart';
import '../../support/store_fixtures.dart';

void main() {
  group('Home UI Redesign', () {
    testWidgets('promo banner adapts to narrow width, large text and direction',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final locale in [const Locale('en'), const Locale('ar')]) {
        final copy = AppLocalizations(locale).home;
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: HomePromoBanner(
              tag: copy.promoTag,
              title: copy.promoTitle,
              highlight: copy.promoHighlight,
              subtitle: copy.promoSubtitle,
              ctaLabel: copy.promoCta,
            ),
          ),
        ));
        await tester.pump();

        expect(find.text(copy.promoTag), findsOneWidget);
        expect(find.text(copy.promoTitle), findsOneWidget);
        expect(find.text(copy.promoHighlight), findsOneWidget);
        expect(find.text(copy.promoSubtitle), findsOneWidget);
        expect(find.text(copy.promoCta), findsOneWidget);
        expect(
          find.byIcon(locale.languageCode == 'ar'
              ? Icons.arrow_back
              : Icons.arrow_forward),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    });

    final categories = List.generate(
      4,
      (i) => homeCategory(id: '$i', nameAr: 'قسم $i', nameEn: 'Cat $i'),
    );
    const restaurants = <Store>[testStore];

    testWidgets('categories use the horizontal rail on narrow mobile 320px',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeCategories(categories: categories),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final rail = tester.widget<ListView>(
          find.byKey(const PageStorageKey('home_categories_rail')));
      expect(rail.scrollDirection, Axis.horizontal);
      expect(find.byKey(const Key('category_card_0')), findsOneWidget);
      expect(find.text('Cat 0'), findsOneWidget);
      await tester.drag(find.byKey(const PageStorageKey('home_categories_rail')),
          const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category_card_3')), findsOneWidget);
      expect(find.text('Cat 3'), findsOneWidget);
    });

    testWidgets('search bar draws a flat pill without a shadow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: HomeSearchBar(hintText: 'Search')),
        ),
      );
      await tester.pump();
      expect(find.byType(HomeSearchBar), findsOneWidget);

      final pill = tester.widget<Container>(
        find.byKey(const Key('home_search_bar')),
      );
      final decoration = pill.decoration! as BoxDecoration;
      // The field is flat against the header band: a hairline ring marks it
      // instead of a drop shadow, which would read as a floating card.
      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
      expect(decoration.borderRadius, AppRadius.pillRadius);
      expect(decoration.border, isNotNull);
    });

    testWidgets('restaurant cards show actual API data', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HomeRestaurantsSection(
          restaurants: restaurants, status: HomeRestaurantsStatus.success,
        )),
      ));
      await tester.pump();
      expect(find.text('Nile Kitchen'), findsOneWidget);
      // Once for the section title, once for the card's category line.
      expect(find.text('Restaurants'), findsNWidgets(2));
      expect(find.text('Sohag'), findsOneWidget);
    });

    testWidgets('supports Arabic RTL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: Scaffold(
            body: HomeCategories(categories: categories),
          ),
        ),
      );
      await tester.pump();
      final dir =
          tester.widget<Directionality>(find.byType(Directionality).first);
      expect(dir.textDirection, TextDirection.rtl);
      expect(find.text('قسم 0'), findsOneWidget);
    });

    testWidgets('supports dark theme without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  HomeCategories(categories: categories),
                  HomeRestaurantsSection(restaurants: restaurants),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow 320px prevents overflow for full home', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const HomeSearchBar(hintText: 'Search'),
                  HomeCategories(categories: categories),
                  HomeRestaurantsSection(restaurants: restaurants),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
