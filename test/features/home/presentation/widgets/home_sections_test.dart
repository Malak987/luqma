import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/home/domain/entities/restaurant_summary.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_categories.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_restaurants_section.dart';

void main() {
  Future<void> pumpSection(WidgetTester tester, Widget section) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: section,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('HomeCategories', () {
    testWidgets('renders one chip per category the API supplies',
        (tester) async {
      await pumpSection(
        tester,
        const HomeCategories(
          categories: <HomeCategory>[
            HomeCategory(id: 'grills', name: 'Grills'),
            HomeCategory(id: 'desserts', name: 'Desserts'),
          ],
        ),
      );

      expect(find.widgetWithText(Chip, 'Grills'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Desserts'), findsOneWidget);
      expect(find.text('Categories will appear here soon'), findsNothing);
    });

    testWidgets('shows the empty state instead of sample categories',
        (tester) async {
      await pumpSection(
        tester,
        const HomeCategories(categories: <HomeCategory>[]),
      );

      expect(find.text('Categories will appear here soon'), findsOneWidget);
      expect(find.byType(Chip), findsNothing);
    });
  });

  group('HomeRestaurantsSection', () {
    testWidgets('renders one card per restaurant the API supplies',
        (tester) async {
      await pumpSection(
        tester,
        const HomeRestaurantsSection(
          restaurants: <RestaurantSummary>[
            RestaurantSummary(id: '1', name: 'Koshary House'),
            RestaurantSummary(id: '2', name: 'Grill Spot'),
          ],
        ),
      );

      expect(find.text('Koshary House'), findsOneWidget);
      expect(find.text('Grill Spot'), findsOneWidget);
      expect(find.text('Restaurants will appear here soon'), findsNothing);
    });

    testWidgets('shows the empty state instead of sample restaurants',
        (tester) async {
      await pumpSection(
        tester,
        const HomeRestaurantsSection(restaurants: <RestaurantSummary>[]),
      );

      expect(find.text('Restaurants will appear here soon'), findsOneWidget);
    });

    testWidgets('uses a placeholder when a restaurant has no artwork',
        (tester) async {
      await pumpSection(
        tester,
        const HomeRestaurantsSection(
          restaurants: <RestaurantSummary>[
            RestaurantSummary(id: '1', name: 'Koshary House'),
          ],
        ),
      );

      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    });

    testWidgets('degrades to the placeholder when the artwork cannot load',
        (tester) async {
      await pumpSection(
        tester,
        const HomeRestaurantsSection(
          restaurants: <RestaurantSummary>[
            RestaurantSummary(
              id: '1',
              name: 'Koshary House',
              imageUrl: 'https://example.test/art.png',
            ),
          ],
        ),
      );

      expect(find.text('Koshary House'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
