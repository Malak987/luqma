import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/store_discovery_view.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/restaurants/presentation/pages/restaurants_tab.dart';

import '../../../home/support/main_category_fixtures.dart';
import '../../../home/support/store_fixtures.dart';

void main() {
  testWidgets('unresolved category is reported as unsupported, not empty stores',
      (tester) async {
    final categories = FakeMainCategoryRepository(
      categories: <HomeCategory>[
        homeCategory(nameAr: 'مأكولات بحرية', nameEn: 'Seafood'),
      ],
    );
    final stores = HomeStoreDependencies();
    final cubit = HomeCubit(
      secureStorageService: _Storage(),
      getAllMainCategoriesUseCase: GetAllMainCategoriesUseCase(categories),
      getStoresUseCase: stores.useCase,
      catalogPaging: stores.paging,
    );
    addTearDown(cubit.close);

    await cubit.loadCategories();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<HomeCubit>.value(
        value: cubit,
        child: const RestaurantsTab(),
      ),
    ));
    await tester.pump();

    expect(
      find.text('No recognized restaurants category is available right now'),
      findsOneWidget,
    );
    expect(find.text('No stores match your selection'), findsNothing);
    expect(find.byType(StoreDiscoveryView), findsNothing);
    expect(stores.repository.calls, 0);
  });
}

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());

  @override
  Future<String?> getUserName() async => 'Tester';
}
