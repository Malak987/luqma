import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/core/routing/catalog_route_arguments.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_cuisines_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_stores_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_discovery_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/pages/invalid_catalog_route_page.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_details_page.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_discovery_page.dart';

import '../../features/catalog/support/menu_fixtures.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });
  tearDown(() async {
    await sl.reset();
  });

  Future<GlobalKey<NavigatorState>> pumpRouter(WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const Scaffold(body: Text('Root')),
    ));
    await tester.pumpAndSettle();
    return key;
  }

  test(
      'typed route validation accepts only real UUID context and bilingual names',
      () {
    expect(
        const StoreDiscoveryArguments(
                mainCategoryId: categoryId,
                nameAr: 'مطاعم',
                nameEn: 'Restaurants')
            .isValid,
        isTrue);
    expect(
        const StoreDiscoveryArguments(
                mainCategoryId: 'invalid',
                nameAr: 'مطاعم',
                nameEn: 'Restaurants')
            .isValid,
        isFalse);
    expect(
        const StoreDiscoveryArguments(
                mainCategoryId: categoryId, nameAr: ' ', nameEn: 'Restaurants')
            .isValid,
        isFalse);
    expect(StoreDetailsArguments(store: store()).isValid, isTrue);
    expect(StoreDetailsArguments(store: store(id: '')).isValid, isFalse);
  });

  testWidgets(
      'invalid/missing arguments never resolve dependencies or call an API',
      (tester) async {
    final navigator = await pumpRouter(tester);
    // No Cubit or HTTP dependency is registered: resolving either would fail.
    for (final route in [AppRoutes.storeDiscovery, AppRoutes.storeDetails]) {
      for (final args in <Object?>[
        null,
        categoryId,
        {'id': categoryId},
        const StoreDiscoveryArguments(
            mainCategoryId: 'bad', nameAr: 'مطاعم', nameEn: 'Restaurants'),
        StoreDetailsArguments(store: store(id: 'bad')),
      ]) {
        unawaited(
            navigator.currentState!.pushNamed<void>(route, arguments: args));
        await tester.pumpAndSettle();
        expect(find.byType(InvalidCatalogRoutePage), findsOneWidget);
        expect(tester.takeException(), isNull);
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets(
      'discovery owns and disposes a fresh parameterized cubit per visit',
      (tester) async {
    final repository = FakeDiscoveryRepository();
    final created = <StoreDiscoveryCubit>[];
    sl.registerFactoryParam<StoreDiscoveryCubit, String, void>((id, _) {
      final cubit = StoreDiscoveryCubit(
          mainCategoryId: id,
          getActiveCuisines: GetActiveCuisinesUseCase(repository),
          getStores: GetStoresUseCase(repository),
          paging: const CatalogPaging());
      created.add(cubit);
      return cubit;
    });
    final navigator = await pumpRouter(tester);
    const arguments = StoreDiscoveryArguments(
        mainCategoryId: categoryId, nameAr: 'مطاعم', nameEn: 'Restaurants');
    for (var visit = 0; visit < 2; visit++) {
      unawaited(navigator.currentState!
          .pushNamed<void>(AppRoutes.storeDiscovery, arguments: arguments));
      await tester.pumpAndSettle();
      expect(find.byType(StoreDiscoveryPage), findsOneWidget);
      expect(created.length, visit + 1);
      expect(repository.queries.last.mainCategoryId, categoryId);
      expect(find.text(categoryId), findsNothing);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(created.last.isClosed, isTrue);
    }
    expect(created.first, isNot(same(created.last)));
  });

  testWidgets(
      'details keep the exact Store snapshot and own a fresh store-scoped menu Cubit per visit',
      (tester) async {
    final repository = FakeMenuRepository();
    final created = <StoreMenuCubit>[];
    sl.registerFactoryParam<StoreMenuCubit, String, void>((id, _) {
      final cubit = StoreMenuCubit(
          storeId: id,
          getCategories: GetActiveMenuCategoriesUseCase(repository),
          getItems: GetMenuItemsUseCase(repository),
          paging: const CatalogPaging());
      created.add(cubit);
      return cubit;
    });
    // Only menu dependencies are registered. A Store/GetById or discovery
    // dependency resolved by details would fail this test.
    final navigator = await pumpRouter(tester);
    final snapshot = store(open: false);
    for (var visit = 0; visit < 2; visit++) {
      unawaited(navigator.currentState!.pushNamed<void>(AppRoutes.storeDetails,
          arguments: StoreDetailsArguments(store: snapshot)));
      await tester.pumpAndSettle();
      expect(
          tester.widget<StoreDetailsPage>(find.byType(StoreDetailsPage)).store,
          same(snapshot));
      expect(find.text('Nile Kitchen'), findsOneWidget);
      expect(find.text('Closed now'), findsOneWidget);
      expect(find.text(storeId), findsNothing);
      expect(repository.categoryStores.length, visit + 1);
      expect(repository.categoryStores.last, storeId);
      expect(repository.queries.last.storeId, storeId);
      expect(repository.queries.last.filters.menuCategoryId, isNull);
      expect(tester.takeException(), isNull);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(created.last.isClosed, isTrue);
    }
    expect(created.length, 2);
    expect(created.first, isNot(same(created.last)));
  });
}
