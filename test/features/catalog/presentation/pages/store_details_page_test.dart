import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_category_tabs.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_details_page.dart';

import '../../support/menu_fixtures.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      for (final open in [false, true]) {
        testWidgets(
            '${locale.languageCode} ${dark ? 'dark' : 'light'} snapshot status=$open',
            (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final snapshot = store(
              open: open,
              nameEn: 'Nile Kitchen with a long store name',
              nameAr: 'مطعم النيل مع اسم مطعم طويل لاختبار العرض');
          await tester.pumpWidget(MaterialApp(
            locale: locale,
            theme: dark ? AppTheme.dark : AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true),
                child: child!),
            home: withMenu(StoreDetailsPage(store: snapshot)),
          ));
          await tester.pumpAndSettle();
          final copy = AppLocalizations(locale).catalog;
          expect(
              find.text(locale.languageCode == 'ar'
                  ? snapshot.nameAr
                  : snapshot.nameEn),
              findsOneWidget);
          expect(find.text(open ? copy.open : copy.closed), findsOneWidget);
          expect(find.text(storeId), findsNothing);
          expect(find.text(categoryId), findsNothing);
          expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('optional phone/category metadata comes from the snapshot',
      (tester) async {
    final snapshot = store(
        phoneNumber: '+20 100 000 0000',
        categoryNameAr: 'مطاعم',
        categoryNameEn: 'Restaurants');
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: withMenu(StoreDetailsPage(store: snapshot))));
    await tester.pumpAndSettle();
    expect(find.text('مطاعم'), findsOneWidget);
    expect(find.text('الهاتف'), findsOneWidget);
    expect(find.text('+20 100 000 0000'), findsOneWidget);
    expect(tester.widget<Text>(find.text('+20 100 000 0000')).textDirection,
        TextDirection.ltr);
  });

  testWidgets(
      'missing optional metadata uses honest fallback and no fake hours/prices',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: withMenu(StoreDetailsPage(store: store(address: null))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nile Kitchen'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    final categoryTabs = find.byType(MenuCategoryTabs);
    await tester.ensureVisible(categoryTabs);
    await tester.pumpAndSettle();
    expect(categoryTabs, findsOneWidget);
    expect(find.text('All categories'), findsOneWidget);
    expect(find.textContaining('4.8'), findsNothing);
    expect(find.textContaining('Free delivery'), findsNothing);
    expect(find.byType(ChoiceChip),
        findsOneWidget); // real empty response: All only
    expect(find.byIcon(Icons.shopping_bag), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

// Preserve all snapshot/header assertions while supplying the newly authorized
// route-scoped menu dependency. No Store/GetById dependency exists.
Widget withMenu(Widget child) {
  final repository = FakeMenuRepository();
  return BlocProvider<StoreMenuCubit>(
    create: (_) => StoreMenuCubit(
        storeId: storeId,
        getCategories: GetActiveMenuCategoriesUseCase(repository),
        getItems: GetMenuItemsUseCase(repository),
        paging: const CatalogPaging()),
    child: child,
  );
}
