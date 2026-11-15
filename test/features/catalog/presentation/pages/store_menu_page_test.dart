import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/domain/entities/catalog_page.dart';
import 'package:luqma_app/features/catalog/domain/entities/menu_category.dart';
import 'package:luqma_app/features/catalog/domain/entities/menu_item.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_details_page.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/catalog_choice_selector.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_card.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_details_sheet.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/store_details_header.dart';

import '../../support/menu_fixtures.dart';

void main() {
  Future<(StoreMenuCubit, GlobalKey<_TestAppState>)> pumpMenu(
      WidgetTester tester, FakeMenuRepository repository,
      {bool settle = true,
      Size size = const Size(390, 844),
      Locale locale = const Locale('en'),
      bool dark = false,
      double scale = 1,
      bool reducedMotion = true}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = StoreMenuCubit(
        storeId: storeId,
        getCategories: GetActiveMenuCategoriesUseCase(repository),
        getItems: GetMenuItemsUseCase(repository),
        paging: const CatalogPaging());
    final key = GlobalKey<_TestAppState>();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      if (!cubit.isClosed) await cubit.close();
    });
    await tester.pumpWidget(BlocProvider<StoreMenuCubit>.value(
        value: cubit,
        child: _TestApp(
            key: key,
            initialLocale: locale,
            initialDark: dark,
            scale: scale,
            reducedMotion: reducedMotion)));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
    return (cubit, key);
  }

  FakeMenuRepository readyRepository() {
    final repository = FakeMenuRepository()
      ..categories = [
        menuCategory(),
        menuCategory(
            id: otherMenuCategoryId,
            order: 0,
            nameAr: 'مقبلات',
            nameEn: 'Starters')
      ];
    repository.onItems = (q) async => menuPage(number: q.pageNumber, items: [
          menuItem(category: q.filters.menuCategoryId ?? menuCategoryId)
        ]);
    return repository;
  }

  Finder verticalScrollable() => find
      .descendant(
          of: find.byKey(const PageStorageKey('store_details_scroll')),
          matching: find.byType(Scrollable))
      .first;
  Finder detailsScrollable() => find
      .descendant(
          of: find.byKey(const PageStorageKey('menu_details_scroll')),
          matching: find.byType(Scrollable))
      .first;
  Finder field(String key) => find.descendant(
      of: find.byKey(Key(key)), matching: find.byType(TextField));
  Future<void> showProducts(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('menu_products_anchor')));
    await tester.pumpAndSettle();
  }

  Future<void> openDetails(WidgetTester tester) async {
    await showProducts(tester);
    await tester.scrollUntilVisible(
        find.byKey(ValueKey('menu_details_$menuItemId')), 200,
        scrollable: verticalScrollable());
    await tester.tap(find.byKey(ValueKey('menu_details_$menuItemId')));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'products succeed while categories are pending, then independent retry remains usable',
      (tester) async {
    final categories = Completer<List<MenuCategory>>();
    final repository = readyRepository()
      ..onCategories = (_) => categories.future;
    final (cubit, _) = await pumpMenu(tester, repository, settle: false);
    await tester.pump();
    expect(repository.queries.length, 1);
    expect(cubit.state.products.items.single.id, menuItemId);
    categories
        .completeError(const FailureException(Failure(FailureCode.network)));
    await tester.pumpAndSettle();
    await showProducts(tester);
    expect(find.byType(MenuItemCard), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('menu_categories_retry')));
    repository.onCategories = null;
    await tester.tap(find.byKey(const Key('menu_categories_retry')));
    await tester.pumpAndSettle();
    expect(repository.queries.length, 1);
    expect(repository.categoryStores.length, 2);
    expect(find.byKey(const Key('menu_categories_error')), findsNothing);
  });

  testWidgets(
      'product error/retry/empty feedback does not reload or hide category choices',
      (tester) async {
    final repository = readyRepository();
    repository.onItems =
        (_) async => throw const FailureException(Failure(FailureCode.network));
    await pumpMenu(tester, repository);
    await showProducts(tester);
    expect(find.byKey(const Key('menu_products_error')), findsOneWidget);
    final choices = tester
        .widget<CatalogChoiceSelector>(find.byType(CatalogChoiceSelector));
    expect(choices.choices.map((choice) => choice.id),
        [otherMenuCategoryId, menuCategoryId]);
    repository.onItems = (_) async => menuPage();
    await tester.ensureVisible(find.byKey(const Key('menu_products_retry')));
    await tester.tap(find.byKey(const Key('menu_products_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu_products_empty')), findsOneWidget);
    expect(repository.categoryStores.length, 1);
    expect(repository.queries.length, 2);
    expect(tester.takeException(), isNull);
  });

  for (final reduced in [false, true]) {
    testWidgets(
        'category changes in place and reveals the persistent products anchor; reduced=$reduced',
        (tester) async {
      final next = Completer<CatalogPage<MenuItem>>();
      final repository = readyRepository();
      repository.onItems = (q) => q.filters.menuCategoryId == null
          ? Future.value(menuPage(
              items: List.generate(
                  20, (i) => menuItem(id: testCatalogId(400 + i)))))
          : next.future;
      final (cubit, _) =
          await pumpMenu(tester, repository, reducedMotion: reduced);
      final anchor =
          tester.element(find.byKey(const Key('menu_products_anchor')));
      final choice = find.byKey(ValueKey('catalog_choice_$menuCategoryId'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pump();
      await tester
          .pump(reduced ? Duration.zero : const Duration(milliseconds: 250));
      expect(tester.element(find.byKey(const Key('menu_products_anchor'))),
          same(anchor));
      final bounds =
          tester.getRect(find.byKey(const Key('menu_products_anchor')));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.bottom, lessThan(844));
      expect(find.byKey(const Key('menu_products_loading')), findsOneWidget);
      expect(find.byType(StoreDetailsPage), findsOneWidget);
      expect(cubit.state.filters.menuCategoryId, menuCategoryId);
      expect(repository.queries.last.pageNumber, 1);
      expect(repository.categoryStores.length, 1);
      next.complete(menuPage(items: [menuItem()]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'lazy products initially request one page and append near the end without jumping',
      (tester) async {
    final next = Completer<CatalogPage<MenuItem>>();
    final repository = readyRepository();
    repository.onItems = (q) => q.pageNumber == 1
        ? Future.value(menuPage(
            items: List.generate(20,
                (i) => menuItem(id: testCatalogId(400 + i), nameEn: 'Dish $i')),
            pages: 2,
            count: 21,
            next: true))
        : next.future;
    await pumpMenu(tester, repository);
    expect(repository.queries.length, 1);
    expect(find.byType(MenuItemCard).evaluate().length, lessThan(20));
    for (var i = 0; i < 12 && repository.queries.length == 1; i++) {
      await tester.drag(verticalScrollable(), const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(repository.queries.map((q) => q.pageNumber), [1, 2]);
    final scroll = tester
        .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('store_details_scroll')))
        .controller!;
    scroll.jumpTo(
        scroll.offset); // end any test gesture's residual ballistic motion
    await tester.pump();
    final offset = scroll.offset;
    expect(offset, greaterThan(0));
    next.complete(menuPage(
        items: [menuItem(id: otherMenuItemId)],
        number: 2,
        pages: 2,
        count: 21,
        previous: true));
    await tester.pumpAndSettle();
    expect(scroll.offset, closeTo(offset, 1));
    expect(repository.queries.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'footer loading/failure and appending do not rebuild header/categories/unchanged cards',
      (tester) async {
    final next = Completer<CatalogPage<MenuItem>>();
    final repository = readyRepository();
    repository.onItems = (q) => q.pageNumber == 1
        ? Future.value(menuPage(items: [menuItem()], next: true, pages: 2))
        : next.future;
    final (cubit, _) =
        await pumpMenu(tester, repository, size: const Size(760, 1500));
    await showProducts(tester);
    final header =
        tester.widget<StoreDetailsHeader>(find.byType(StoreDetailsHeader));
    final choices = tester
        .widget<CatalogChoiceSelector>(find.byType(CatalogChoiceSelector));
    final card = tester.widget<MenuItemCard>(find.byType(MenuItemCard));
    final pending = cubit.loadNextPage();
    await tester.pump();
    expect(tester.widget<MenuItemCard>(find.byType(MenuItemCard)), same(card));
    next.completeError(const FailureException(Failure(FailureCode.network)));
    await pending;
    await tester.pumpAndSettle();
    expect(tester.widget<MenuItemCard>(find.byType(MenuItemCard)), same(card));
    repository.onItems = (q) async => menuPage(
        items: [menuItem(id: otherMenuItemId)],
        number: q.pageNumber,
        previous: true);
    await cubit.retryNextPage();
    await tester.pumpAndSettle();
    expect(tester.widget<StoreDetailsHeader>(find.byType(StoreDetailsHeader)),
        same(header));
    expect(
        tester
            .widget<CatalogChoiceSelector>(find.byType(CatalogChoiceSelector)),
        same(choices));
    expect(
        tester.widget<MenuItemCard>(find.byWidgetPredicate(
            (w) => w is MenuItemCard && w.item.id == menuItemId)),
        same(card));
  });

  testWidgets(
      'retained results show explicit same-page footer retry, with no automatic retry loop',
      (tester) async {
    var failed = true;
    final repository = readyRepository();
    repository.onItems = (q) async {
      if (q.pageNumber == 1)
        return menuPage(items: [menuItem()], next: true, pages: 2);
      if (failed) throw const FailureException(Failure(FailureCode.network));
      return menuPage(
          items: [menuItem(id: otherMenuItemId)], number: 2, previous: true);
    };
    await pumpMenu(tester, repository);
    await showProducts(tester);
    await tester.ensureVisible(find.byKey(const Key('pagination_more')));
    await tester.tap(find.byKey(const Key('pagination_more')));
    await tester.pumpAndSettle();
    expect(find.text('Nile dish'), findsOneWidget);
    expect(find.textContaining('More products could not load'), findsOneWidget);
    expect(repository.queries.map((q) => q.pageNumber), [1, 2]);
    failed = false;
    await tester.ensureVisible(find.byKey(const Key('pagination_retry')));
    await tester.tap(find.byKey(const Key('pagination_retry')));
    await tester.pumpAndSettle();
    expect(repository.queries.map((q) => q.pageNumber), [1, 2, 2]);
    expect(find.byKey(const Key('pagination_retry')), findsNothing);
  });

  testWidgets(
      'debounced search and validated Arabic price/sale filters use documented values only',
      (tester) async {
    final repository = readyRepository();
    final (cubit, _) = await pumpMenu(tester, repository);
    await tester.ensureVisible(field('menu_search'));
    await tester.enterText(field('menu_search'), 'rice');
    await tester.pump(const Duration(milliseconds: 200));
    expect(repository.queries.length, 1);
    await tester.enterText(field('menu_search'), '  rice bowl  ');
    await tester.pump(const Duration(milliseconds: 349));
    expect(repository.queries.length, 1);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(cubit.state.filters.search, 'rice bowl');
    final expand = find.byKey(const PageStorageKey('menu_product_filters'));
    await tester.ensureVisible(expand);
    await tester.tap(find.text('Filter products'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(field('menu_min_price'));
    await tester.enterText(field('menu_min_price'), '٢٠٫٥');
    await tester.enterText(field('menu_max_price'), '١٠');
    await tester.ensureVisible(find.byKey(const Key('menu_apply_prices')));
    await tester.tap(find.byKey(const Key('menu_apply_prices')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu_price_error')), findsOneWidget);
    expect(repository.queries.length, 2);
    await tester.ensureVisible(field('menu_max_price'));
    await tester.enterText(field('menu_max_price'), '٥٠');
    await tester.ensureVisible(find.byKey(const Key('menu_apply_prices')));
    await tester.tap(find.byKey(const Key('menu_apply_prices')));
    await tester.pumpAndSettle();
    expect(cubit.state.filters.minPrice, 20.5);
    expect(cubit.state.filters.maxPrice, 50);
    await tester.ensureVisible(find.byKey(const Key('menu_sale_only')));
    await tester.tap(find.byKey(const Key('menu_sale_only')));
    await tester.pumpAndSettle();
    expect(repository.queries.last.filters.saleOnly, isTrue);
    expect(repository.queries.last.filters.search, 'rice bowl');
    expect(repository.categoryStores.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'options are single-choice and addons independent; saved IDs survive reopening with no cart request',
      (tester) async {
    final repository = readyRepository();
    final anotherOption = testCatalogId(202);
    repository.onItems = (_) async => menuPage(items: [
          menuItem(soldByWeight: true, options: [
            const MenuItemOption(
                id: optionId, nameAr: 'عادي', nameEn: 'Regular', price: 25),
            MenuItemOption(
                id: anotherOption, nameAr: 'كبير', nameEn: 'Large', price: 40)
          ], addons: [
            const MenuItemAddon(
                id: optionId, nameAr: 'جبن', nameEn: 'Cheese', price: 4),
            const MenuItemAddon(
                id: addonId,
                nameAr: 'صلصة',
                nameEn: 'Sauce',
                price: 2,
                imageUrl: 'invalid')
          ])
        ]);
    await pumpMenu(tester, repository);
    await openDetails(tester);
    await tester.scrollUntilVisible(
        find.byKey(ValueKey('menu_option_$optionId')), 200,
        scrollable: detailsScrollable());
    await tester.tap(find.byKey(ValueKey('menu_option_$optionId')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(ValueKey('menu_addon_$optionId')), 200,
        scrollable: detailsScrollable());
    await tester.tap(find.byKey(ValueKey('menu_addon_$optionId')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(ValueKey('menu_addon_$optionId')))
            .value,
        isTrue);
    await tester
        .ensureVisible(find.byKey(ValueKey('menu_option_$anotherOption')));
    await tester.tap(find.byKey(ValueKey('menu_option_$anotherOption')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<RadioListTile<String>>(
                find.byKey(ValueKey('menu_option_$anotherOption')))
            .groupValue,
        anotherOption);
    await tester.tap(find.byKey(const Key('menu_save_choices')));
    await tester.pumpAndSettle();
    await openDetails(tester);
    await tester.scrollUntilVisible(
        find.byKey(ValueKey('menu_option_$anotherOption')), 200,
        scrollable: detailsScrollable());
    expect(
        tester
            .widget<RadioListTile<String>>(
                find.byKey(ValueKey('menu_option_$anotherOption')))
            .groupValue,
        anotherOption);
    await tester.scrollUntilVisible(
        find.byKey(ValueKey('menu_addon_$optionId')), 200,
        scrollable: detailsScrollable());
    expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(ValueKey('menu_addon_$optionId')))
            .value,
        isTrue);
    expect(find.byType(Slider), findsNothing);
    expect(find.text(optionId), findsNothing);
    expect(find.byIcon(Icons.shopping_bag), findsNothing);
    final unsavedAddon = find.byKey(ValueKey('menu_addon_$addonId'));
    await tester.scrollUntilVisible(unsavedAddon, 150,
        scrollable: detailsScrollable());
    await tester.tap(unsavedAddon);
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(const Key('menu_details_close'))); // cancel, do not save
    await tester.pumpAndSettle();
    await openDetails(tester);
    await tester.scrollUntilVisible(unsavedAddon, 150,
        scrollable: detailsScrollable());
    expect(tester.widget<CheckboxListTile>(unsavedAddon).value, isFalse);
    await tester.tap(find.byKey(const Key('menu_details_close')));
    await tester.pumpAndSettle();
    expect(repository.queries.length, 1);
    expect(repository.categoryStores.length, 1);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets(
          '${locale.languageCode} ${dark ? 'dark' : 'light'} menu/details at 320px and 200% text',
          (tester) async {
        final repository = readyRepository();
        repository.onItems = (_) async => menuPage(items: [
              menuItem(soldByWeight: true, weight: .75, options: const [
                MenuItemOption(
                    id: optionId,
                    nameAr: 'خيار طويل لاختبار حجم الخط واتجاه العرض',
                    nameEn: 'An option with a long localized label',
                    price: 25.5)
              ], addons: const [
                MenuItemAddon(
                    id: addonId,
                    nameAr: 'إضافة اختيارية مع صورة غير متاحة',
                    nameEn: 'An optional addon with unavailable artwork',
                    price: 4,
                    imageUrl: 'invalid')
              ])
            ]);
        await pumpMenu(tester, repository,
            locale: locale, dark: dark, scale: 2, size: const Size(320, 568));
        await openDetails(tester);
        final copy = AppLocalizations(locale).catalog;
        final sheet = find.byType(MenuItemDetailsSheet);
        expect(
            Directionality.of(tester.element(sheet)),
            locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr);
        final facts =
            find.descendant(of: sheet, matching: find.byType(MenuItemPrice));
        final price =
            find.descendant(of: facts, matching: find.text(copy.number(25.5)));
        await tester.scrollUntilVisible(price, 150,
            scrollable: detailsScrollable());
        expect(price, findsOneWidget);
        expect(find.descendant(of: facts, matching: find.text(copy.number(30))),
            findsOneWidget);
        expect(find.descendant(of: facts, matching: find.text(copy.sale)),
            findsOneWidget);
        final weight = find.descendant(
            of: sheet,
            matching: find.text('${copy.weight}: ${copy.number(.75)}'));
        await tester.scrollUntilVisible(weight, 150,
            scrollable: detailsScrollable());
        expect(weight, findsOneWidget);
        await tester.scrollUntilVisible(
            find.byKey(ValueKey('menu_addon_$addonId')), 150,
            scrollable: detailsScrollable());
        expect(
            tester
                .widget<CheckboxListTile>(
                    find.byKey(ValueKey('menu_addon_$addonId')))
                .value,
            isFalse);
        final scheme =
            Theme.of(tester.element(sheet)).extension<AppSemanticColors>()!;
        expect(scheme.primary, const Color(0xFF7B1E28));
        expect(scheme.background,
            dark ? AppSemanticColors.dark.background : const Color(0xFFF6F1E7));
        expect(find.text(menuItemId), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'an open details sheet updates locale/theme without losing chosen IDs or refetching',
      (tester) async {
    final repository = readyRepository();
    repository.onItems = (_) async => menuPage(items: [
          menuItem(options: const [
            MenuItemOption(
                id: optionId, nameAr: 'عادي', nameEn: 'Regular', price: 25.5)
          ])
        ]);
    final (_, app) = await pumpMenu(tester, repository);
    await openDetails(tester);
    final option = find.byKey(ValueKey('menu_option_$optionId'));
    await tester.scrollUntilVisible(option, 150,
        scrollable: detailsScrollable());
    await tester.tap(option);
    await tester.pumpAndSettle();
    app.currentState!.switchLocaleAndTheme();
    await tester.pumpAndSettle();
    final sheet = find.byType(MenuItemDetailsSheet);
    expect(Directionality.of(tester.element(sheet)), TextDirection.rtl);
    expect(tester.widget<RadioListTile<String>>(option).groupValue, optionId);
    expect(find.text('عادي'), findsOneWidget);
    final surface = tester.widget<Material>(
        find.descendant(of: sheet, matching: find.byType(Material)).first);
    expect(surface.color, AppSemanticColors.dark.surface);
    expect(repository.queries.length, 1);
    expect(repository.categoryStores.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'locale/theme changes preserve selected category, filters and loaded pages without refetch',
      (tester) async {
    final repository = readyRepository();
    repository.onItems = (q) async => menuPage(
        number: q.pageNumber,
        items: [
          menuItem(
              id: q.pageNumber == 1 ? menuItemId : otherMenuItemId,
              category: q.filters.menuCategoryId ?? menuCategoryId)
        ],
        pages: 2,
        count: 2,
        next: q.pageNumber == 1,
        previous: q.pageNumber == 2);
    final (cubit, app) = await pumpMenu(tester, repository);
    await cubit.selectCategory(menuCategoryId);
    await cubit.search('dish');
    await cubit.loadNextPage();
    await tester.pumpAndSettle();
    final calls = repository.queries.length;
    app.currentState!.switchLocaleAndTheme();
    await tester.pumpAndSettle();
    await showProducts(tester);
    expect(cubit.state.products.items.length, 2);
    expect(cubit.state.products.pageNumber, 2);
    expect(cubit.state.filters.menuCategoryId, menuCategoryId);
    expect(cubit.state.filters.search, 'dish');
    expect(find.text('طبق النيل'), findsWidgets);
    expect(repository.queries.length, calls);
    expect(repository.categoryStores.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing the page cancels a pending search debounce',
      (tester) async {
    final repository = readyRepository();
    final (cubit, _) = await pumpMenu(tester, repository);
    await tester.ensureVisible(field('menu_search'));
    await tester.enterText(field('menu_search'), 'pending');
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
    await tester.pump(const Duration(milliseconds: 400));
    expect(repository.queries.length, 1);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatefulWidget {
  const _TestApp(
      {required this.initialLocale,
      required this.initialDark,
      required this.scale,
      required this.reducedMotion,
      super.key});
  final Locale initialLocale;
  final bool initialDark;
  final double scale;
  final bool reducedMotion;
  @override
  State<_TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<_TestApp> {
  late Locale locale = widget.initialLocale;
  late bool dark = widget.initialDark;
  void switchLocaleAndTheme() => setState(() {
        locale = const Locale('ar');
        dark = true;
      });
  @override
  Widget build(BuildContext context) => MaterialApp(
        locale: locale,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(widget.scale),
                disableAnimations: widget.reducedMotion,
                accessibleNavigation: widget.reducedMotion),
            child: child!),
        home: StoreDetailsPage(store: store()),
      );
}
