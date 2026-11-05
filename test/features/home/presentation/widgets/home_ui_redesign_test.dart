import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/home/domain/entities/restaurant_summary.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_categories.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_restaurants_section.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_search_bar.dart';

void main() {
  group('Home UI Redesign', () {
    final categories = List.generate(4, (i) => HomeCategory(id: '$i', name: 'Cat $i'));
    final restaurants = List.generate(3, (i) => RestaurantSummary(id: '$i', name: 'Restaurant $i'));

    testWidgets('categories grid is two columns on narrow mobile 320px', (tester) async {
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
      // Verify GridView exists and has 2 columns via delegate
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      // Check no overflow
      expect(find.byKey(const Key('category_card_0')), findsOneWidget);
    });

    testWidgets('search bar is visually improved with elevated container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HomeSearchBar(hintText: 'Search')),
        ),
      );
      await tester.pump();
      expect(find.byType(HomeSearchBar), findsOneWidget);
      // Should have container with shadow
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('restaurant cards have premium hierarchy with image/name/meta', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HomeRestaurantsSection(restaurants: restaurants)),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('restaurant_card_0')), findsOneWidget);
      expect(find.text('Restaurant 0'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('Free delivery'), findsOneWidget);
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
      final dir = tester.widget<Directionality>(find.byType(Directionality).first);
      expect(dir.textDirection, TextDirection.rtl);
      expect(find.text('Cat 0'), findsOneWidget);
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
                  HomeSearchBar(hintText: 'Search'),
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
