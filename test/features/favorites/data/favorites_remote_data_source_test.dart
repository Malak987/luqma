import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/favorites/data/datasources/favorites_remote_data_source.dart';

import '../support/favorite_fixtures.dart';

void main() {
  test('Favorite endpoints use authenticated Dio and exact supplied contracts',
      () async {
    final harness = _Harness();

    expect(
      (await harness.source.addToFavorites(favoriteMenuItemId)).menuItemId,
      favoriteMenuItemId,
    );
    harness.expectRequest(
      method: 'POST',
      path: ApiConstants.addToFavorites,
      body: <String, Object>{'menuItemId': favoriteMenuItemId},
    );

    await harness.source.removeFromFavorites(favoriteMenuItemId);
    harness.expectRequest(
      method: 'DELETE',
      path: ApiConstants.removeFromFavorites(favoriteMenuItemId),
    );

    expect(
      (await harness.source.getMyFavorites(pageNumber: 1, pageSize: 20))
          .totalCount,
      1,
    );
    harness.expectRequest(
      method: 'GET',
      path: ApiConstants.getMyFavorites,
      query: const <String, Object>{'pageNumber': 1, 'pageSize': 20},
    );

    expect(await harness.source.isFavorite(favoriteMenuItemId), isTrue);
    harness.expectRequest(
      method: 'GET',
      path: ApiConstants.isFavorite(favoriteMenuItemId),
    );
    expect(await harness.source.getCount(), 1);
    harness.expectRequest(method: 'GET', path: ApiConstants.getFavoritesCount);
    expect(harness.storage.tokenReads, 5);
  });

  test('Favorite envelope and network errors follow existing failures',
      () async {
    final rejected = _Harness(
      body: favoriteEnvelope(data: null, succeeded: false, message: 'Nope'),
    );
    await expectLater(
      rejected.source.getCount(),
      throwsA(
        isA<RemoteException>().having(
          (error) => error.code,
          'code',
          FailureCode.validation,
        ),
      ),
    );

    final offline = _Harness(failure: DioExceptionType.connectionError);
    await expectLater(
      offline.source.isFavorite(favoriteMenuItemId),
      throwsA(
        isA<RemoteException>().having(
          (error) => error.code,
          'code',
          FailureCode.network,
        ),
      ),
    );
  });
}

class _Harness {
  _Harness({Object? body, DioExceptionType? failure}) {
    final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    addTearDown(() => dio.close(force: true));
    final client = DioClient(storage, dio: dio);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          if (failure != null) {
            handler.reject(
              DioException(requestOptions: options, type: failure),
            );
            return;
          }
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: body ?? _bodyFor(options.path),
            ),
          );
        },
      ),
    );
    source = FavoritesRemoteDataSourceImpl(client);
  }

  final _Storage storage = _Storage();
  late final FavoritesRemoteDataSourceImpl source;
  RequestOptions? request;

  Object _bodyFor(String path) {
    if (path == ApiConstants.getMyFavorites) {
      return favoriteEnvelope(
        data: favoritePageJson(
          items: <Object?>[favoriteItemJson()],
          totalCount: 1,
        ),
      );
    }
    if (path == ApiConstants.getFavoritesCount) {
      return favoriteEnvelope(data: 1);
    }
    if (path == ApiConstants.isFavorite(favoriteMenuItemId)) {
      return favoriteEnvelope(data: true);
    }
    return favoriteEnvelope(data: favoriteItemJson());
  }

  void expectRequest({
    required String method,
    required String path,
    Object? body,
    Map<String, Object>? query,
  }) {
    expect(request?.method, method);
    expect(request?.path, path);
    expect(request?.extra[DioClient.requiresAuthenticationExtraKey], isTrue);
    expect(request?.headers['Authorization'], 'Bearer test-token');
    expect(request?.data, body);
    if (query != null) expect(request?.queryParameters, query);
  }
}

class _Storage extends SecureStorageService {
  _Storage() : super(const FlutterSecureStorage());
  int tokenReads = 0;

  @override
  Future<String?> getToken() async {
    tokenReads++;
    return 'test-token';
  }
}
