import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:luqma_app/features/cart/data/models/cart_mutation_request_model.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_mutation.dart';

import '../support/cart_fixtures.dart';

void main() {
  test(
    'all Cart endpoints use protected Dio requests and exact routes',
    () async {
      final harness = _Harness();
      final request = CartMutationRequestModel.fromDomain(
        CartMutation(
          menuItemId: cartMenuItemId,
          quantity: 2,
          menuItemOptionId: cartOptionId,
          addonIds: const <String>[cartAddonId],
        ),
      );

      expect((await harness.source.addToCart(request)).id, cartLineId);
      harness.expectRequest(
        method: 'POST',
        path: ApiConstants.addToCart,
        body: <String, Object>{
          'menuItemId': cartMenuItemId,
          'quantity': 2,
          'menuItemOptionId': cartOptionId,
          'addonIds': const <String>[cartAddonId],
        },
      );
      expect((await harness.source.updateToCart(request)).quantity, 2);
      harness.expectRequest(
        method: 'PUT',
        path: ApiConstants.updateToCart,
        body: <String, Object>{
          'menuItemId': cartMenuItemId,
          'quantity': 2,
          'menuItemOptionId': cartOptionId,
          'addonIds': const <String>[cartAddonId],
        },
      );
      expect((await harness.source.getMyCart()).subTotal, 540);
      harness.expectRequest(method: 'GET', path: ApiConstants.getMyCart);
      expect((await harness.source.getCount()).totalQuantity, 2);
      harness.expectRequest(method: 'GET', path: ApiConstants.getCartCount);
      expect(harness.storage.tokenReads, 4);
    },
  );

  test(
    'unsuccessful envelope and network failures follow failure conventions',
    () async {
      final rejected = _Harness(
        body: cartEnvelope(data: null, succeeded: false, message: 'No cart'),
      );
      await expectLater(
        rejected.source.getMyCart(),
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
        offline.source.getCount(),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            FailureCode.network,
          ),
        ),
      );
    },
  );
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
          final data = body ?? _bodyFor(options.path);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
    source = CartRemoteDataSourceImpl(client);
  }

  final _Storage storage = _Storage();
  late final CartRemoteDataSourceImpl source;
  RequestOptions? request;

  Object _bodyFor(String path) {
    if (path == ApiConstants.getMyCart) {
      return cartEnvelope(
        data: cartJson(
          items: <Object?>[cartLineJson()],
          totalQuantity: 2,
          subTotal: 540,
        ),
      );
    }
    if (path == ApiConstants.getCartCount) {
      return cartEnvelope(data: cartCountJson(linesCount: 1, totalQuantity: 2));
    }
    return cartEnvelope(data: cartLineJson());
  }

  void expectRequest({
    required String method,
    required String path,
    Object? body,
  }) {
    expect(request?.method, method);
    expect(request?.path, path);
    expect(request?.extra[DioClient.requiresAuthenticationExtraKey], isTrue);
    expect(request?.headers['Authorization'], 'Bearer test-token');
    expect(request?.data, body);
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
