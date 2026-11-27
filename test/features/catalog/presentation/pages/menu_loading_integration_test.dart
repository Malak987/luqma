import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_menu_remote_data_source.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_menu_repository_impl.dart';
import 'package:luqma_app/features/catalog/domain/queries/catalog_paging.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_menu_items_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_cubit.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_menu_state.dart';
import 'package:luqma_app/features/catalog/presentation/pages/store_details_page.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/menu_item_card.dart';
import '../../../cart/support/cart_fixtures.dart';
import '../../support/menu_fixtures.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    for (final dark in [false, true]) {
      testWidgets(
          'API-shaped page with null compare price renders $locale dark=$dark',
          (tester) async {
        final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        final client = DioClient(
            SecureStorageService(const FlutterSecureStorage()),
            dio: dio);
        final requests = <RequestOptions>[];
        dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
          requests.add(options);
          final data = options.path == ApiConstants.getAllMenuCategories
              ? catalogEnvelope(data: [menuCategoryJson()])
              : menuResponseJson(items: [
                  menuItemJson()
                    ..['compareAtPrice'] = null
                    ..['imageUrl'] = null
                ], count: 1);
          handler.resolve(Response<Object?>(
              requestOptions: options, statusCode: 200, data: data));
        }));
        final repo =
            StoreMenuRepositoryImpl(StoreMenuRemoteDataSourceImpl(client));
        final cubit = StoreMenuCubit(
            storeId: storeId,
            getCategories: GetActiveMenuCategoriesUseCase(repo),
            getItems: GetMenuItemsUseCase(repo),
            paging: const CatalogPaging());
        final cartRepo = FakeCartRepository();
        final cart = CartCubit(
            addToCartUseCase: AddToCartUseCase(cartRepo),
            updateToCartUseCase: UpdateToCartUseCase(cartRepo),
            clearCartUseCase: ClearCartUseCase(cartRepo),
            getMyCartUseCase: GetMyCartUseCase(cartRepo));
        addTearDown(() async {
          await cubit.close();
          await cart.close();
          dio.close(force: true);
        });
        await tester.pumpWidget(MultiBlocProvider(
            providers: [
              BlocProvider<StoreMenuCubit>.value(value: cubit),
              BlocProvider<CartCubit>.value(value: cart)
            ],
            child: MaterialApp(
              locale: locale,
              theme: dark ? AppTheme.dark : AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: StoreDetailsPage(store: store()),
            )));
        await tester.pumpAndSettle();
        expect(cubit.state.categories.status, MenuStatus.success);
        expect(cubit.state.products.status, MenuStatus.success);
        expect(cubit.state.products.items.single.compareAtPrice, isNull);
        final product = find.byKey(ValueKey('menu_item_$menuItemId'));
        await tester.scrollUntilVisible(product, 200,
            scrollable: find
                .descendant(
                    of: find
                        .byKey(const PageStorageKey('store_details_scroll')),
                    matching: find.byType(Scrollable))
                .first);
        expect(product, findsOneWidget);
        expect(find.byType(MenuArtworkPlaceholder), findsOneWidget);
        expect(
            find.text(locale.languageCode == 'ar' ? 'طبق النيل' : 'Nile dish'),
            findsOneWidget);
        expect(requests.length, 2);
        expect(requests.every((r) => r.queryParameters['storeId'] == storeId),
            isTrue);
        expect(
            requests.every((r) =>
                !r.headers.keys.any((k) => k.toLowerCase() == 'authorization')),
            isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
