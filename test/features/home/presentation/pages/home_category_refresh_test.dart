import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';
import '../../support/main_category_fixtures.dart';
import '../../support/store_fixtures.dart';

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());
  @override
  Future<String?> getUserName() async => 'User';
}

void main() {
  testWidgets(
      'visible Home refreshes categories after three minutes without clearing them',
      (tester) async {
    final categories = FakeMainCategoryRepository(categories: [homeCategory()]);
    final stores = HomeStoreDependencies();
    final cubit = HomeCubit(
        secureStorageService: _Storage(),
        getAllMainCategoriesUseCase: GetAllMainCategoriesUseCase(categories),
        getStoresUseCase: stores.useCase,
        catalogPaging: stores.paging);
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomePage(),
        )));
    await tester.pump();
    await tester.pump();
    expect(categories.calls, 1);
    expect(cubit.state.categories, [homeCategory()]);
    await tester.pump(const Duration(minutes: 3));
    await tester.pump();
    expect(categories.calls, 2);
    expect(cubit.state.categories, [homeCategory()]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
