import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/store_card.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_state.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_categories.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_restaurants_section.dart';

import '../../support/main_category_fixtures.dart';
import '../../support/store_fixtures.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    Widget section, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
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
    await tester.pump();
  }

  group('HomeCategories', () {
    testWidgets('renders one card per category the API supplies',
        (tester) async {
      await pumpSection(
        tester,
        HomeCategories(
          categories: <HomeCategory>[
            homeCategory(id: 'grills', nameAr: 'مشويات', nameEn: 'Grills'),
            homeCategory(id: 'desserts', nameAr: 'حلويات', nameEn: 'Desserts'),
          ],
        ),
      );

      expect(find.byKey(const Key('category_card_grills')), findsOneWidget);
      expect(find.byKey(const Key('category_card_desserts')), findsOneWidget);
      expect(find.text('Grills'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);
      expect(find.text('No categories are available right now'), findsNothing);
    });

    testWidgets('shows the empty state instead of sample categories',
        (tester) async {
      await pumpSection(
        tester,
        const HomeCategories(categories: <HomeCategory>[]),
      );

      expect(
          find.text('No categories are available right now'), findsOneWidget);
      expect(
          find.byKey(const PageStorageKey('home_categories_rail')), findsNothing);
    });
  });

  group('HomeRestaurantsSection', () {
    testWidgets('renders real Store fields', (tester) async {
      await pumpSection(tester, const HomeRestaurantsSection(
        restaurants: <Store>[testStore],
      ));
      expect(find.text('Nile Kitchen'), findsOneWidget);
      expect(find.text('Restaurants'), findsNWidgets(2));
      expect(find.text('Sohag'), findsOneWidget);
      expect(find.text('No restaurants are available right now'), findsNothing);
    });

    testWidgets('uses localized Store fields and a backward arrow in Arabic RTL', (tester) async {
      await pumpSection(tester, const HomeRestaurantsSection(
        restaurants: <Store>[testStore],
      ), locale: const Locale('ar'));
      expect(find.text('مطعم النيل'), findsOneWidget);
      expect(find.text('مطاعم'), findsNWidgets(2));
      expect(find.text('Sohag'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('uses semantic dark-theme surfaces and colors', (tester) async {
      await pumpSection(tester, const HomeRestaurantsSection(
        restaurants: <Store>[testStore],
      ), theme: AppTheme.dark);
      final storeCard = find.byType(StoreCard);
      final material = tester.widget<Material>(find.descendant(
        of: storeCard, matching: find.byType(Material)).first);
      final colors = Theme.of(tester.element(storeCard))
          .extension<AppSemanticColors>()!;
      expect(material.color, colors.surface);
      expect(find.text('Nile Kitchen'), findsOneWidget);
    });

    testWidgets('uses a static accessible loading indicator for reduced motion',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(body: HomeRestaurantsSection(
            restaurants: <Store>[], status: HomeRestaurantsStatus.loading,
          )),
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.bySemanticsLabel('Loading restaurants'), findsOneWidget);
    });

    testWidgets('uses placeholders for absent or failed Store artwork', (tester) async {
      await pumpSection(tester, const HomeRestaurantsSection(
        restaurants: <Store>[Store(
          id: 'missing-image', nameAr: 'بلا صورة', nameEn: 'No Image',
          mainCategoryId: mainCategoryId,
          isActive: true, isOpenNow: true,
        )],
      ));
      expect(find.text('No Image'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);

      await pumpSection(tester, const HomeRestaurantsSection(
        restaurants: <Store>[Store(
          id: 'failed-image', nameAr: 'صورة تالفة', nameEn: 'Broken Image',
          mainCategoryId: mainCategoryId,
          isActive: true, isOpenNow: true,
          iconUrl: 'https://example.test/broken.png',
        )],
      ));
      await tester.pumpAndSettle();
      // TestWidgetsFlutterBinding rejects network images; the image request is
      // present while AppNetworkImage's errorBuilder renders the fallback.
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Broken Image'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
      expect(find.byKey(const Key('app_network_image_error')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows loading, empty, and unavailable states', (tester) async {
      await pumpSection(tester, const HomeRestaurantsSection(
        restaurants: <Store>[], status: HomeRestaurantsStatus.loading,
      ));
      expect(find.byKey(const Key('home_restaurants_loading')), findsOneWidget);

      await pumpSection(tester, const HomeRestaurantsSection(
        restaurants: <Store>[], status: HomeRestaurantsStatus.empty,
      ));
      expect(find.byKey(const Key('home_restaurants_empty')), findsOneWidget);

      await pumpSection(tester, const HomeRestaurantsSection(
        restaurants: <Store>[], status: HomeRestaurantsStatus.unavailable,
      ));
      expect(find.byKey(const Key('home_restaurants_unavailable')), findsOneWidget);
    });

    testWidgets('retry uses HomeCubit, preserves categories, and recovers', (tester) async {
      final categories = FakeMainCategoryRepository(
        categories: <HomeCategory>[homeCategory()],
      );
      final stores = HomeStoreDependencies();
      stores.repository.error = StateError('offline');
      final cubit = HomeCubit(
        secureStorageService: _Storage(),
        getAllMainCategoriesUseCase: GetAllMainCategoriesUseCase(categories),
        getStoresUseCase: stores.useCase,
        catalogPaging: stores.paging,
      );
      addTearDown(cubit.close);
      await cubit.loadCategories();
      expect(cubit.state.restaurantsStatus, HomeRestaurantsStatus.error);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<HomeCubit>.value(
          value: cubit,
          child: Scaffold(body: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) => HomeRestaurantsSection(
              restaurants: state.restaurants,
              status: state.restaurantsStatus,
              onRetry: context.read<HomeCubit>().retryRestaurants,
            ),
          )),
        ),
      ));
      await tester.pump();
      expect(find.byKey(const Key('home_restaurants_error')), findsOneWidget);

      stores.repository.error = null;
      stores.repository.stores = const <Store>[testStore];
      await tester.tap(find.byKey(const Key('home_restaurants_retry')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(categories.calls, 1);
      expect(stores.repository.calls, 2);
      expect(cubit.state.restaurantsStatus, HomeRestaurantsStatus.success);
      expect(find.text('Nile Kitchen'), findsOneWidget);
    });

    testWidgets('shows error with retry action', (tester) async {
      var retried = false;
      await pumpSection(tester, HomeRestaurantsSection(
        restaurants: const <Store>[], status: HomeRestaurantsStatus.error,
        onRetry: () => retried = true,
      ));
      expect(find.byKey(const Key('home_restaurants_error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('home_restaurants_retry')));
      expect(retried, isTrue);
    });
  });
}

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getUserName() async => 'Tester';
}
