import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/catalog/data/datasources/store_discovery_remote_data_source.dart';
import 'package:luqma_app/features/catalog/domain/queries/store_query.dart';

import '../support/catalog_fixtures.dart';

void main() {
  test('Cuisine is an anonymous GET with onlyActive=true', () async {
    final harness = _Harness(body: catalogEnvelope(data: [cuisineJson()]));
    expect((await harness.source.getActiveCuisines()).single.id, cuisineId);
    expect(harness.request?.method, 'GET');
    expect(harness.request?.path, '/api/Cuisine/GetAll');
    expect(harness.request?.queryParameters, {'onlyActive': true});
    harness.expectPublic();
  });

  test(
      'Store always scopes active stores; All and Open Now OFF omit optional keys',
      () async {
    final harness =
        _Harness(body: storeResponseJson(items: [storeJson()], count: 1));
    expect(
        (await harness.source.getStores(const StoreQuery(
          mainCategoryId: categoryId,
          pageNumber: 1,
          pageSize: 20,
        )))
            .items
            .single
            .id,
        storeId);
    expect(harness.request?.method, 'GET');
    expect(harness.request?.path, '/api/Store/GetAll');
    expect(harness.request?.queryParameters, {
      'mainCategoryId': categoryId,
      'isActive': true,
      'pageNumber': 1,
      'pageSize': 20,
    });
    expect(harness.request?.data, isNull);
    harness.expectPublic();
  });

  test('only selected actual cuisine and enabled Open Now are added', () async {
    final harness =
        _Harness(body: storeResponseJson(number: 3, previous: true));
    await harness.source.getStores(const StoreQuery(
      mainCategoryId: categoryId,
      cuisineId: cuisineId,
      openNowOnly: true,
      pageNumber: 3,
      pageSize: 10,
    ));
    expect(harness.request?.queryParameters, {
      'mainCategoryId': categoryId,
      'cuisineId': cuisineId,
      'isActive': true,
      'isOpenNow': true,
      'pageNumber': 3,
      'pageSize': 10,
    });
    harness.expectPublic();
  });

  for (final type in <DioExceptionType>[
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.transformTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.badCertificate,
    DioExceptionType.cancel,
    DioExceptionType.unknown,
  ]) {
    for (final stores in [false, true]) {
      test(
          '${stores ? 'Store' : 'Cuisine'} maps $type without touching the session',
          () async {
        final harness = _Harness(failure: type);
        await expectLater(
            stores
                ? harness.source.getStores(const StoreQuery(
                    mainCategoryId: categoryId,
                    pageNumber: 1,
                    pageSize: 20,
                  ))
                : harness.source.getActiveCuisines(),
            throwsA(isA<RemoteException>().having(
              (e) => e.code,
              'code',
              type == DioExceptionType.cancel ||
                      type == DioExceptionType.unknown
                  ? FailureCode.unknown
                  : FailureCode.network,
            )));
        harness.expectPublic();
      });
    }
  }

  for (final entry in {
    400: FailureCode.validation,
    401: FailureCode.invalidCredentials,
    403: FailureCode.invalidCredentials,
    502: FailureCode.unknown
  }.entries) {
    test('HTTP ${entry.key} is a section failure, not logout', () async {
      final harness = _Harness(
          failure: DioExceptionType.badResponse,
          status: entry.key,
          body: '<html>Error with untrusted content</html>');
      await expectLater(
          harness.source.getActiveCuisines(),
          throwsA(isA<RemoteException>()
              .having((e) => e.code, 'code', entry.value)));
      harness.expectPublic();
    });
  }

  test('failed envelopes and malformed data cannot masquerade as empty success',
      () async {
    for (final stores in [false, true]) {
      final malformed = _Harness(body: {'items': []});
      await expectLater(
          stores
              ? malformed.source.getStores(const StoreQuery(
                  mainCategoryId: categoryId,
                  pageNumber: 1,
                  pageSize: 20,
                ))
              : malformed.source.getActiveCuisines(),
          throwsA(isA<RemoteException>()
              .having((e) => e.code, 'code', FailureCode.unknown)));
      final rejected =
          _Harness(body: catalogEnvelope(data: null, succeeded: false));
      await expectLater(
          stores
              ? rejected.source.getStores(const StoreQuery(
                  mainCategoryId: categoryId,
                  pageNumber: 1,
                  pageSize: 20,
                ))
              : rejected.source.getActiveCuisines(),
          throwsA(isA<RemoteException>()
              .having((e) => e.code, 'code', FailureCode.validation)));
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
    source = StoreDiscoveryRemoteDataSourceImpl(client);
  }
  final storage = _Storage();
  late final StoreDiscoveryRemoteDataSourceImpl source;
  RequestOptions? request;

  void expectPublic() {
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
