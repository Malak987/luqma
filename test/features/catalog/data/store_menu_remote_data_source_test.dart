import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_menu_remote_data_source.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_filters.dart';
import 'package:luqma_app/features/catalog/domain/queries/menu_item_query.dart';

import '../support/menu_fixtures.dart';

const _query = MenuItemQuery(storeId: storeId, pageNumber: 1, pageSize: 20);

void main() {
  test('MenuCategory anonymous GET has only real storeId and onlyActive=true',
      () async {
    final harness = _Harness(body: catalogEnvelope(data: [menuCategoryJson()]));
    expect((await harness.source.getActiveCategories(storeId)).single.id,
        menuCategoryId);
    expect(harness.request?.path, '/api/MenuCategory/GetAll');
    expect(harness.request?.queryParameters,
        {'storeId': storeId, 'onlyActive': true});
    harness.expectPublic();
  });

  test(
      'MenuItem All omits category/search/price/sale/sort; active store paging is always explicit',
      () async {
    final harness = _Harness(body: menuResponseJson(items: [menuItemJson()]));
    expect((await harness.source.getItems(_query)).items.single.id, menuItemId);
    expect(harness.request?.path, '/api/MenuItem/GetAll');
    expect(harness.request?.queryParameters, {
      'storeId': storeId,
      'isActive': true,
      'pageNumber': 1,
      'pageSize': 20,
    });
    harness.expectPublic();
  });

  test(
      'only actual category UUID and documented optional filters are sent on subsequent pages',
      () async {
    final harness = _Harness(body: menuResponseJson(number: 3, previous: true));
    await harness.source.getItems(const MenuItemQuery(
        storeId: storeId,
        pageNumber: 3,
        pageSize: 8,
        filters: MenuItemFilters(
            menuCategoryId: menuCategoryId,
            search: '  طبق  ',
            minPrice: 0.0,
            maxPrice: 99.75,
            saleOnly: true)));
    expect(harness.request?.queryParameters, {
      'storeId': storeId,
      'isActive': true,
      'pageNumber': 3,
      'pageSize': 8,
      'menuCategoryId': menuCategoryId,
      'search': 'طبق',
      'minPrice': 0.0,
      'maxPrice': 99.75,
      'onSale': true,
    });
    expect(harness.request?.queryParameters.containsKey('sortBy'), isFalse);
    harness.expectPublic();
    await harness.source.getItems(const MenuItemQuery(
        storeId: storeId,
        pageNumber: 3,
        pageSize: 8,
        filters: MenuItemFilters(search: '   ')));
    expect(harness.request?.queryParameters.keys.toSet(),
        {'storeId', 'isActive', 'pageNumber', 'pageSize'});
  });

  for (final type in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.transformTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.badCertificate,
    DioExceptionType.cancel,
    DioExceptionType.unknown,
  ]) {
    for (final products in [false, true]) {
      test(
          '${products ? 'products' : 'categories'} maps $type without token/session access',
          () async {
        final harness = _Harness(failure: type);
        await expectLater(
            products
                ? harness.source.getItems(_query)
                : harness.source.getActiveCategories(storeId),
            throwsA(isA<RemoteException>().having(
                (e) => e.code,
                'code',
                type == DioExceptionType.cancel ||
                        type == DioExceptionType.unknown
                    ? FailureCode.unknown
                    : FailureCode.network)));
        harness.expectPublic();
      });
    }
  }

  for (final entry in {
    400: FailureCode.validation,
    401: FailureCode.invalidCredentials,
    403: FailureCode.invalidCredentials,
    404: FailureCode.unknown,
    500: FailureCode.unknown
  }.entries) {
    test('HTTP ${entry.key} is a local section failure, never logout',
        () async {
      final harness = _Harness(
          failure: DioExceptionType.badResponse,
          status: entry.key,
          body: 'Untrusted response');
      await expectLater(
          harness.source.getItems(_query),
          throwsA(isA<RemoteException>()
              .having((e) => e.code, 'code', entry.value)));
      harness.expectPublic();
    });
  }

  test(
      'malformed successful wrappers and rejected envelopes never masquerade as empty menu',
      () async {
    for (final products in [false, true]) {
      for (final body in [
        catalogEnvelope(data: null, succeeded: false),
        catalogEnvelope(data: products ? [] : {'items': []}),
        {'items': []}
      ]) {
        final harness = _Harness(body: body);
        await expectLater(
            products
                ? harness.source.getItems(_query)
                : harness.source.getActiveCategories(storeId),
            throwsA(isA<RemoteException>()));
        harness.expectPublic();
      }
    }
  });
}

class _Harness {
  _Harness({Object? body, DioExceptionType? failure, int? status}) {
    final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {'aUtHoRiZaTiOn': 'Bearer stale'}));
    addTearDown(() => dio.close(force: true));
    final client = DioClient(storage, dio: dio);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      request = options;
      if (failure == null) {
        handler.resolve(Response<Object?>(
            requestOptions: options, statusCode: 200, data: body));
      } else {
        handler.reject(DioException(
            requestOptions: options,
            type: failure,
            response: status == null
                ? null
                : Response<Object?>(
                    requestOptions: options, statusCode: status, data: body)));
      }
    }));
    source = StoreMenuRemoteDataSourceImpl(client);
  }
  final storage = _Storage();
  late final StoreMenuRemoteDataSourceImpl source;
  RequestOptions? request;

  void expectPublic() {
    expect(request?.method, 'GET');
    expect(request?.data, isNull);
    expect(
        request?.headers.keys
            .any((key) => key.toLowerCase() == 'authorization'),
        isFalse);
    expect(
        request?.extra[DioClient.requiresAuthenticationExtraKey], isNot(true));
    expect(storage.tokenReads, 0);
    expect(storage.clears, 0);
  }
}

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());
  int tokenReads = 0;
  int clears = 0;
  @override
  Future<String?> getToken() async {
    tokenReads++;
    return 'never-used';
  }

  @override
  Future<void> clearAuthData() async {
    clears++;
  }
}
