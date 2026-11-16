import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/core/routing/catalog_route_arguments.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';

import '../../support/main_category_fixtures.dart';
import '../../support/store_fixtures.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets(
        'Home ${locale.languageCode} category passes actual UUID and both names',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final category = homeCategory();
      final repository = FakeMainCategoryRepository(categories: [category]);
      RouteSettings? captured;
      await tester.pumpWidget(BlocProvider<HomeCubit>(
        create: (_) => HomeCubit(
            secureStorageService: _Storage(),
            getAllMainCategoriesUseCase:
                GetAllMainCategoriesUseCase(repository),
            getStoresUseCase: testGetStoresUseCase(),
            catalogPaging: const CatalogPaging()),
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          onGenerateRoute: (settings) {
            captured = settings;
            return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) =>
                    const Scaffold(body: Text('Discovery destination')));
          },
          home: const HomePage(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(mainCategoryId), findsNothing);
      await tester.tap(find.byKey(Key('category_card_$mainCategoryId')));
      await tester.pumpAndSettle();
      expect(captured?.name, AppRoutes.storeDiscovery);
      final args = captured?.arguments as StoreDiscoveryArguments;
      expect(args.mainCategoryId, category.id);
      expect(args.nameAr, category.nameAr);
      expect(args.nameEn, category.nameEn);
      expect(args.isValid, isTrue);
      expect(repository.calls, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());
  @override
  Future<String?> getUserName() async => 'Malak';
}
