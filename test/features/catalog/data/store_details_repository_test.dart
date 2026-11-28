import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/catalog/data/repositories/store_details_repository_impl.dart';
import 'package:luqma_app/features/catalog/domain/repositories/store_details_repository.dart';
import '../support/catalog_fixtures.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_store_details_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_details_cubit.dart';

void main() {
  test(
      'deduplicates concurrent requests, caches by store and location, expires and preserves failed snapshot',
      () async {
    var now = DateTime.utc(2026, 1, 1);
    final requests = <RequestOptions>[];
    final blocked = Completer<void>();
    final started = Completer<void>();
    var fail = false;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, handler) async {
      requests.add(o);
      if (!started.isCompleted) started.complete();
      if (requests.length == 1) await blocked.future;
      if (fail) {
        handler.reject(DioException(
            requestOptions: o, type: DioExceptionType.connectionError));
      } else {
        final id = o.path.split('/').last;
        handler.resolve(Response(
            requestOptions: o,
            statusCode: 200,
            data: catalogEnvelope(data: storeJson(id: id))));
      }
    }));
    final repo = StoreDetailsRepositoryImpl(
        DioClient(SecureStorageService(const FlutterSecureStorage()), dio: dio),
        clock: () => now);
    final first = repo.get(storeId);
    final second = repo.get(storeId.toUpperCase());
    await started.future;
    expect(requests.length, 1);
    expect(requests.single.queryParameters, isEmpty);
    blocked.complete();
    final a = await first;
    final b = await second;
    expect(a.store.id, storeId);
    expect(b.store.id, storeId);
    await repo.get(storeId);
    expect(requests.length, 1);
    final other = await repo.get(otherStoreId);
    expect(other.store.id, otherStoreId);
    expect(requests.length, 2);
    const location = StoreDetailsLocation(26.56, 31.69);
    await repo.get(storeId, location: location);
    expect(requests.length, 3);
    expect(
        requests.last.queryParameters, {'latitude': 26.56, 'longitude': 31.69});
    now = now.add(const Duration(minutes: 3));
    fail = true;
    await expectLater(repo.get(storeId), throwsA(isA<FailureException>()));
    expect(requests.length, 4);
    expect(repo.cached(storeId, null)?.store, a.store);
    await expectLater(
        repo.get(storeId, location: const StoreDetailsLocation(200, 0)),
        throwsA(isA<FailureException>()));
    expect(requests.length, 4);
  });
  test('does not cache mismatched store response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    var count = 0;
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      count++;
      h.resolve(Response(
          requestOptions: o,
          statusCode: 200,
          data: catalogEnvelope(data: storeJson(id: otherStoreId))));
    }));
    final repo = StoreDetailsRepositoryImpl(DioClient(
        SecureStorageService(const FlutterSecureStorage()),
        dio: dio));
    await expectLater(repo.get(storeId), throwsA(isA<FailureException>()));
    expect(repo.cached(storeId, null), isNull);
    await expectLater(repo.get(storeId), throwsA(isA<FailureException>()));
    expect(count, 2);
  });
  test('two independently opened details routes share one HTTP request',
      () async {
    var count = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      count++;
      h.resolve(Response(
          requestOptions: o,
          statusCode: 200,
          data: catalogEnvelope(data: storeJson())));
    }));
    final repo = StoreDetailsRepositoryImpl(DioClient(
        SecureStorageService(const FlutterSecureStorage()),
        dio: dio));
    final get = GetStoreDetailsUseCase(repo);
    final a = StoreDetailsCubit(initial: store(), getDetails: get);
    final b = StoreDetailsCubit(initial: store(), getDetails: get);
    await Future.wait([a.load(), b.load()]);
    final c = StoreDetailsCubit(initial: store(), getDetails: get);
    await c.load();
    expect(count, 1);
    expect(a.state.store.id, storeId);
    expect(b.state.store.id, storeId);
    expect(c.state.store.id, storeId);
    // ignore: avoid_print
    print('HTTP details count for 3 independent visits: GetById=$count');
    await a.close();
    await b.close();
    await c.close();
  });
}
