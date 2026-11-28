import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_menu_remote_data_source.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_menu_repository_impl.dart';
import 'package:luqma_app/features/catalog/data/repositories/cached_store_menu_repository.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_details_repository_impl.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_store_details_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_details_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_details_page.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_details_sheet.dart';
import '../../support/cart_test_provider.dart';
import '../../support/menu_fixtures.dart';

class _Addresses implements AddressRepository {
  @override
  Future<List<Address>> getMyAddresses() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Address _address(String id, double lat, double lng) => Address(
    id: id,
    label: AddressLabel.home,
    title: id,
    district: '',
    city: '',
    details: '',
    latitude: lat,
    longitude: lng,
    isDefault: false);
void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets('product sheet return and location update $locale dark=$dark',
          (tester) async {
        final calls = <RequestOptions>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
        dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
          calls.add(o);
          final dynamic data;
          if (o.path.contains('Store/GetById')) {
            data = catalogEnvelope(data: storeJson());
          } else if (o.path.contains('MenuCategory')) {
            data = catalogEnvelope(data: [menuCategoryJson()]);
          } else {
            data = menuResponseJson(items: [menuItemJson()], count: 1);
          }
          h.resolve(Response(requestOptions: o, statusCode: 200, data: data));
        }));
        final client = DioClient(
            SecureStorageService(const FlutterSecureStorage()),
            dio: dio);
        final repo = CachedStoreMenuRepository(
            StoreMenuRepositoryImpl(StoreMenuRemoteDataSourceImpl(client)));
        final menu = StoreMenuCubit(
            storeId: storeId,
            getCategories: GetActiveMenuCategoriesUseCase(repo),
            getItems: GetMenuItemsUseCase(repo),
            paging: const CatalogPaging());
        final details = StoreDetailsCubit(
            initial: store(),
            getDetails:
                GetStoreDetailsUseCase(StoreDetailsRepositoryImpl(client)))
          ..load();
        final address = AddressSetupCubit(
            getMyAddressesUseCase: GetMyAddressesUseCase(_Addresses()));
        addTearDown(() async {
          await menu.close();
          await details.close();
          await address.close();
          dio.close(force: true);
        });
        await tester.pumpWidget(withTestCart(MultiBlocProvider(
            providers: [
              BlocProvider<StoreMenuCubit>.value(value: menu),
              BlocProvider<StoreDetailsCubit>.value(value: details),
              BlocProvider<AddressSetupCubit>.value(value: address),
            ],
            child: MaterialApp(
                locale: locale,
                theme: dark ? AppTheme.dark : AppTheme.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: StoreDetailsPage(store: store())))));
        await tester.pumpAndSettle();
        expect(calls.length, 3);
        final product = find.byKey(ValueKey('menu_item_$menuItemId'));
        await tester.scrollUntilVisible(product, 200,
            scrollable: find
                .descendant(
                    of: find
                        .byKey(const PageStorageKey('store_details_scroll')),
                    matching: find.byType(Scrollable))
                .first);
        await tester.tap(product);
        await tester.pumpAndSettle();
        expect(find.byType(MenuItemDetailsSheet), findsOneWidget);
        Navigator.of(tester.element(find.byType(MenuItemDetailsSheet))).pop();
        await tester.pumpAndSettle();
        expect(calls.length, 3);
        address.onAddressSaved(_address('a', 26, 31));
        await tester.pumpAndSettle();
        expect(calls.length, 4);
        expect(calls.last.path, '/api/Store/GetById/$storeId');
        expect(
            calls.last.queryParameters, {'latitude': 26.0, 'longitude': 31.0});
        address.onAddressSaved(_address('a', 26, 31));
        await tester.pumpAndSettle();
        expect(calls.length, 4);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
