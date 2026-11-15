import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/catalog_route_arguments.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:luqma_app/features/catalog/domain/entities/cuisine.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_cuisines_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_stores_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_discovery_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_details_page.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_discovery_page.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/store_card.dart';

import '../../support/menu_fixtures.dart';

void main() {
  Future<(StoreDiscoveryCubit, GlobalKey<_TestAppState>)> pumpDiscovery(
    WidgetTester tester,
    FakeDiscoveryRepository repository, {
    bool settle = true,
    Size size = const Size(390, 1000),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = StoreDiscoveryCubit(
        mainCategoryId: categoryId,
        getActiveCuisines: GetActiveCuisinesUseCase(repository),
        getStores: GetStoresUseCase(repository),
        paging: const CatalogPaging());
    final key = GlobalKey<_TestAppState>();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
    });
    await tester.pumpWidget(_TestApp(key: key, cubit: cubit));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
    return (cubit, key);
  }

  FakeDiscoveryRepository readyRepository() => FakeDiscoveryRepository()
    ..cuisines = [
      cuisine(),
      cuisine(id: otherCuisineId, nameAr: 'مصري', nameEn: 'Egyptian')
    ]
    ..onStores =
        (query) async => storePage(items: [store(open: query.openNowOnly)]);

  Finder verticalScrollable() => find
      .descendant(
        of: find.byKey(const PageStorageKey('store_discovery_scroll')),
        matching: find.byType(Scrollable),
      )
      .first;

  testWidgets('All and Open Now OFF are usable while independent sections load',
      (tester) async {
    final cuisines = Completer<List<Cuisine>>();
    final stores = Completer<CatalogPage<Store>>();
    final repository = FakeDiscoveryRepository();
    repository.onCuisines = () => cuisines.future;
    repository.onStores = (_) => stores.future;
    await pumpDiscovery(tester, repository, settle: false);
    expect(
        tester
            .widget<ChoiceChip>(
                find.byKey(const ValueKey('catalog_choice_all')))
            .selected,
        isTrue);
    expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('open_now_filter')))
            .value,
        isFalse);
    expect(find.byKey(const Key('stores_loading')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    stores.complete(storePage(items: [store(open: false)]));
    await tester.pump();
    await tester.pump();
    expect(find.text('Nile Kitchen'), findsOneWidget);
    expect(find.text('Closed now'), findsOneWidget); // active != open
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    cuisines.complete([cuisine()]);
    await tester.pumpAndSettle();
    expect(find.text('Italian'), findsOneWidget);
    expect(repository.queries.length, 1);
    expect(find.text(categoryId), findsNothing);
    expect(find.text(storeId), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'cuisines can fail independently, retrying without reloading stores',
      (tester) async {
    final repository = readyRepository()
      ..onCuisines = () async =>
          throw const FailureException(Failure(FailureCode.network));
    await pumpDiscovery(tester, repository);
    expect(find.byKey(const Key('cuisines_error')), findsOneWidget);
    expect(find.text('Nile Kitchen'), findsOneWidget);
    repository.onCuisines = null;
    await tester.tap(find.byKey(const Key('cuisines_retry')));
    await tester.pumpAndSettle();
    expect(repository.cuisineCalls, 2);
    expect(repository.queries.length, 1);
    expect(find.byKey(const Key('cuisines_error')), findsNothing);
  });

  testWidgets(
      'inline cuisine and open filters make no navigation or metadata reload',
      (tester) async {
    final repository = readyRepository();
    final (cubit, _) = await pumpDiscovery(tester, repository);
    await tester.tap(find.byKey(const ValueKey('catalog_choice_$cuisineId')));
    await tester.pumpAndSettle();
    expect(find.byType(StoreDiscoveryPage), findsOneWidget);
    expect(repository.queries.last.cuisineId, cuisineId);
    expect(cubit.state.selectedCuisineId, cuisineId);
    await tester.tap(find.byKey(const Key('open_now_filter')));
    await tester.pumpAndSettle();
    expect(repository.queries.last.openNowOnly, isTrue);
    expect(find.text('Open now'), findsOneWidget);
    final queryCount = repository.queries.length;
    await tester.tap(find.byTooltip('Clear filters'));
    await tester.pumpAndSettle();
    expect(repository.queries, hasLength(queryCount + 1));
    expect(repository.queries.last.cuisineId, isNull);
    expect(repository.queries.last.openNowOnly, isFalse);
    expect(cubit.state.selectedCuisineId, isNull);
    expect(cubit.state.openNowOnly, isFalse);
    await tester.tap(find.byKey(const ValueKey('catalog_choice_all')));
    await tester.pumpAndSettle();
    expect(repository.queries.last.cuisineId, isNull);
    expect(repository.cuisineCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'runtime locale/theme changes retain filters, pages and bilingual data',
      (tester) async {
    final repository = readyRepository();
    final (cubit, host) = await pumpDiscovery(tester, repository);
    await cubit.selectCuisine(cuisineId);
    await cubit.setOpenNowOnly(true);
    await tester.pumpAndSettle();
    final queries = repository.queries.length;
    host.currentState!
        .appearance(locale: const Locale('ar'), mode: ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(find.text('مطاعم'), findsOneWidget);
    expect(find.text('إيطالي'), findsOneWidget);
    expect(find.text('مطعم النيل'), findsOneWidget);
    expect(find.text('مفتوح الآن'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(StoreDiscoveryPage))),
        TextDirection.rtl);
    expect(Theme.of(tester.element(find.byType(StoreCard))).brightness,
        Brightness.dark);
    expect(cubit.state.selectedCuisineId, cuisineId);
    expect(cubit.state.openNowOnly, isTrue);
    expect(repository.queries.length, queries);
    expect(repository.cuisineCalls, 1);
    host.currentState!
        .appearance(locale: const Locale('en'), mode: ThemeMode.light);
    await tester.pumpAndSettle();
    expect(find.text('Nile Kitchen'), findsOneWidget);
    expect(repository.queries.length, queries);
  });

  testWidgets('store error/empty states are separate from loaded cuisines',
      (tester) async {
    final repository = readyRepository()
      ..onStores = (_) async =>
          throw const FailureException(Failure(FailureCode.network));
    await pumpDiscovery(tester, repository);
    expect(find.byKey(const Key('stores_error')), findsOneWidget);
    expect(find.text('Italian'), findsOneWidget);
    repository.onStores = (_) async => storePage();
    await tester.tap(find.byKey(const Key('stores_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stores_empty')), findsOneWidget);
    expect(repository.cuisineCalls, 1);
  });

  testWidgets(
      'tap passes the actual snapshot to details; back retains discovery',
      (tester) async {
    await sl.reset();
    addTearDown(sl.reset);
    final menu = FakeMenuRepository();
    StoreMenuCubit? detailsCubit;
    sl.registerFactoryParam<StoreMenuCubit, String, void>((id, _) {
      return detailsCubit = StoreMenuCubit(
          storeId: id,
          getCategories: GetActiveMenuCategoriesUseCase(menu),
          getItems: GetMenuItemsUseCase(menu),
          paging: const CatalogPaging());
    });
    final snapshot = store(open: false);
    final repository = readyRepository()
      ..onStores = (_) async => storePage(items: [snapshot]);
    final (cubit, _) = await pumpDiscovery(tester, repository);
    await tester.tap(find.text('Nile Kitchen'));
    await tester.pumpAndSettle();
    expect(tester.widget<StoreDetailsPage>(find.byType(StoreDetailsPage)).store,
        same(snapshot));
    expect(find.text('Closed now'), findsOneWidget);
    expect(menu.categoryStores, [snapshot.id]);
    expect(menu.queries.single.storeId, snapshot.id);
    expect(menu.queries.single.filters.menuCategoryId, isNull);
    expect(
        repository.queries.length, 1); // no Store/GetById or discovery reload
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(cubit.isClosed, isFalse);
    expect(detailsCubit!.isClosed, isTrue);
    expect(find.byType(StoreDiscoveryPage), findsOneWidget);
    expect(repository.queries.length, 1);
  });

  testWidgets(
      'lazy list starts with one page and appends near the end without reset',
      (tester) async {
    final next = Completer<CatalogPage<Store>>();
    final repository = readyRepository()
      ..onStores = (query) async {
        if (query.pageNumber == 2) return next.future;
        return storePage(
            items: List.generate(
                20,
                (index) => store(
                      id: testCatalogId(index + 30),
                      nameEn: 'Store ${index + 1}',
                    )),
            next: true,
            pages: 2,
            count: 21);
      };
    await pumpDiscovery(tester, repository, size: const Size(390, 800));
    expect(repository.queries.length, 1);
    expect(find.byType(StoreCard).evaluate().length, lessThan(20));
    await tester.scrollUntilVisible(
        find.byKey(ValueKey('store_${testCatalogId(49)}')), 600,
        scrollable: verticalScrollable(), maxScrolls: 40);
    await tester.pump();
    expect(repository.queries.map((q) => q.pageNumber), [1, 2]);
    expect(find.text('Loading more'), findsOneWidget);
    await tester.drag(
        find.byKey(const PageStorageKey('store_discovery_scroll')),
        const Offset(0, -200));
    await tester.pump();
    expect(repository.queries.length, 2);
    next.complete(storePage(
        number: 2,
        pages: 2,
        count: 21,
        items: [store(id: otherStoreId, nameEn: 'Last Store')]));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(verticalScrollable()).position.pixels,
        greaterThan(0));
    expect(repository.queries.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'footer progress/errors do not rebuild loaded card widgets; retry keeps content',
      (tester) async {
    final pending = Completer<CatalogPage<Store>>();
    final repository = readyRepository()
      ..onStores = (_) async => storePage(items: [store()], next: true);
    final (cubit, _) = await pumpDiscovery(tester, repository);
    final card = tester.widget<StoreCard>(find.byType(StoreCard));
    repository.onStores = (_) => pending.future;
    final append = cubit.loadNextPage();
    await tester.pump();
    expect(tester.widget<StoreCard>(find.byType(StoreCard)), same(card));
    pending.completeError(const FailureException(Failure(FailureCode.network)));
    await append;
    await tester.pumpAndSettle();
    expect(tester.widget<StoreCard>(find.byType(StoreCard)), same(card));
    expect(find.text('Nile Kitchen'), findsOneWidget);
    expect(find.byKey(const Key('pagination_retry')), findsOneWidget);
    repository.onStores =
        (_) async => storePage(number: 2, items: [store(id: otherStoreId)]);
    await tester.tap(find.byKey(const Key('pagination_retry')));
    await tester.pumpAndSettle();
    expect(repository.queries.map((q) => q.pageNumber), [1, 2, 2]);
    expect(cubit.state.stores.items.length, 2);
  });

  testWidgets(
      'reduced motion resets filters immediately, without a paging request',
      (tester) async {
    final repository = readyRepository()
      ..onStores = (_) async => storePage(
          items: List.generate(
              20, (index) => store(id: testCatalogId(index + 30))),
          next: true);
    final (cubit, host) = await pumpDiscovery(tester, repository);
    host.currentState!.appearance(reducedMotion: true);
    await tester.pumpAndSettle();
    await tester.drag(
        find.byKey(const PageStorageKey('store_discovery_scroll')),
        const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(verticalScrollable()).position.pixels,
        greaterThan(0));
    await cubit.setOpenNowOnly(true);
    await tester.pump();
    expect(
        tester.state<ScrollableState>(verticalScrollable()).position.pixels, 0);
    expect(repository.queries.length, 2);
  });

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      testWidgets(
          '${locale.languageCode} $mode tolerates small screens and 200% text',
          (tester) async {
        final repository = readyRepository();
        final (_, host) =
            await pumpDiscovery(tester, repository, size: const Size(320, 568));
        host.currentState!.appearance(locale: locale, mode: mode, textScale: 2);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final semantics = tester.ensureSemantics();
        expect(find.bySemanticsLabel(RegExp(categoryId)), findsNothing);
        expect(find.bySemanticsLabel(RegExp(storeId)), findsNothing);
        semantics.dispose();
      });
    }
  }
}

class _TestApp extends StatefulWidget {
  const _TestApp({required this.cubit, super.key});
  final StoreDiscoveryCubit cubit;
  @override
  State<_TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<_TestApp> {
  Locale locale = const Locale('en');
  ThemeMode mode = ThemeMode.light;
  double textScale = 1;
  bool reducedMotion = false;

  void appearance(
      {Locale? locale,
      ThemeMode? mode,
      double? textScale,
      bool? reducedMotion}) {
    setState(() {
      this.locale = locale ?? this.locale;
      this.mode = mode ?? this.mode;
      this.textScale = textScale ?? this.textScale;
      this.reducedMotion = reducedMotion ?? this.reducedMotion;
    });
  }

  @override
  Widget build(BuildContext context) => BlocProvider<StoreDiscoveryCubit>.value(
        value: widget.cubit,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: reducedMotion,
                accessibleNavigation: reducedMotion),
            child: child!,
          ),
          home: const StoreDiscoveryPage(
              arguments: StoreDiscoveryArguments(
                  mainCategoryId: categoryId,
                  nameAr: 'مطاعم',
                  nameEn: 'Restaurants')),
        ),
      );
}
