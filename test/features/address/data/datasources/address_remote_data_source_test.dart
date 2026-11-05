import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/address/data/datasources/address_remote_data_source.dart';
import 'package:luqma_app/features/address/data/models/create_address_request_model.dart';
import 'package:luqma_app/features/address/domain/entities/address_draft.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';

void main() {
  group('AddressRemoteDataSourceImpl', () {
    test('sends authenticated GET to GetMyAddresses and parses the result',
        () async {
      final harness = _Harness(
        responseData: _envelope(data: <Object?>[_addressJson()]),
      );

      final addresses = await harness.dataSource.getMyAddresses();

      expect(addresses, hasLength(1));
      expect(addresses.single.id, '0ae79d3a-594c-4852-aedf-27d5c176fa70');
      expect(harness.request?.method, 'GET');
      expect(harness.request?.path, ApiConstants.getMyAddresses);
      _expectAuthenticatedRequest(harness);
    });

    test('treats an empty data list as a valid successful response', () async {
      final harness = _Harness(responseData: _envelope(data: <Object?>[]));

      expect(await harness.dataSource.getMyAddresses(), isEmpty);
    });

    test('treats isSucceeded false as a failure', () async {
      final harness = _Harness(
        responseData: _envelope(
          data: null,
          isSucceeded: false,
          message: 'Address request was rejected',
        ),
      );

      await expectLater(
        harness.dataSource.getMyAddresses(),
        throwsA(
          isA<RemoteException>()
              .having((error) => error.code, 'code', FailureCode.validation)
              .having(
                (error) => error.message,
                'message',
                'Address request was rejected',
              ),
        ),
      );
    });

    test('treats missing or malformed data as a parsing failure', () async {
      final missingData = _envelope(data: <Object?>[])..remove('data');
      await expectLater(
        _Harness(responseData: missingData).dataSource.getMyAddresses(),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            FailureCode.unknown,
          ),
        ),
      );

      await expectLater(
        _Harness(responseData: _envelope(data: 'not a list'))
            .dataSource
            .getMyAddresses(),
        throwsA(isA<RemoteException>()),
      );
    });

    test('turns an invalid label into a parsing failure', () async {
      final json = _addressJson()..['label'] = 8;
      final harness = _Harness(
        responseData: _envelope(data: <Object?>[json]),
      );

      await expectLater(
        harness.dataSource.getMyAddresses(),
        throwsA(isA<RemoteException>()),
      );
    });

    test('turns missing address fields into a parsing failure', () async {
      final json = _addressJson()..remove('city');
      final harness = _Harness(
        responseData: _envelope(data: <Object?>[json]),
      );

      await expectLater(
        harness.dataSource.getMyAddresses(),
        throwsA(isA<RemoteException>()),
      );
    });

    test('sends authenticated POST to Create with the complete JSON body',
        () async {
      final harness = _Harness(
        responseData: _envelope(
          data: <String, dynamic>{'undocumentedPayload': true},
        ),
      );
      final request = CreateAddressRequestModel.fromDomain(_draft());

      await harness.dataSource.createAddress(request);

      expect(harness.request?.method, 'POST');
      expect(harness.request?.path, ApiConstants.createAddress);
      expect(
        harness.request?.data,
        <String, dynamic>{
          'label': 2,
          'title': 'Home title',
          'district': 'District',
          'city': 'City',
          'details': 'Building 2',
          'latitude': 26.557,
          'longitude': 31.694,
          'isDefault': true,
        },
      );
      _expectAuthenticatedRequest(harness);
    });

    test('treats an unsuccessful Create envelope as a failure', () async {
      final harness = _Harness(
        responseData: _envelope(data: null, isSucceeded: false),
      );

      await expectLater(
        harness.dataSource.createAddress(
          CreateAddressRequestModel.fromDomain(_draft()),
        ),
        throwsA(isA<RemoteException>()),
      );
    });

    test('maps Dio network and authentication failures distinctly', () async {
      await expectLater(
        _Harness(failureType: DioExceptionType.connectionError)
            .dataSource
            .getMyAddresses(),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            FailureCode.network,
          ),
        ),
      );

      await expectLater(
        _Harness(
          failureType: DioExceptionType.badResponse,
          statusCode: 401,
        ).dataSource.getMyAddresses(),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            FailureCode.invalidCredentials,
          ),
        ),
      );

      await expectLater(
        _Harness(
          failureType: DioExceptionType.badResponse,
          statusCode: 500,
        ).dataSource.getMyAddresses(),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'code',
            FailureCode.unknown,
          ),
        ),
      );
    });
  });
}

void _expectAuthenticatedRequest(_Harness harness) {
  expect(
    harness.request?.extra[DioClient.requiresAuthenticationExtraKey],
    isTrue,
  );
  expect(
    harness.request?.headers['Authorization'],
    'Bearer address-test-token',
  );
  expect(harness.storage.tokenReadCount, 1);
}

Map<String, dynamic> _envelope({
  required Object? data,
  bool isSucceeded = true,
  String message = 'Address request succeeded',
}) => <String, dynamic>{
      'message': message,
      'data': data,
      'isSucceeded': isSucceeded,
      'timestamp': '2026-11-04T17:16:20.4274824Z',
    };

Map<String, dynamic> _addressJson() => <String, dynamic>{
      'id': '0ae79d3a-594c-4852-aedf-27d5c176fa70',
      'label': 0,
      'title': 'string',
      'district': 'string',
      'city': 'string',
      'details': 'string',
      'latitude': 0,
      'longitude': 0,
      'isDefault': true,
    };

AddressDraft _draft() => const AddressDraft(
      label: AddressLabel.other,
      title: 'Home title',
      district: 'District',
      city: 'City',
      details: 'Building 2',
      latitude: 26.557,
      longitude: 31.694,
      isDefault: true,
    );

class _Harness {
  _Harness({
    Object? responseData,
    DioExceptionType? failureType,
    int? statusCode,
  }) {
    final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    storage = _FakeSecureStorageService();
    final client = DioClient(storage, dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          if (failureType != null) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: statusCode == null
                    ? null
                    : Response<dynamic>(
                        requestOptions: options,
                        statusCode: statusCode,
                        data: <String, dynamic>{
                          'message': 'Address request failed',
                        },
                      ),
                type: failureType,
              ),
            );
            return;
          }

          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: responseData,
            ),
          );
        },
      ),
    );

    dataSource = AddressRemoteDataSourceImpl(client);
  }

  late final AddressRemoteDataSourceImpl dataSource;
  late final _FakeSecureStorageService storage;
  RequestOptions? request;
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(const FlutterSecureStorage());

  int tokenReadCount = 0;

  @override
  Future<String?> getToken() async {
    tokenReadCount++;
    return 'address-test-token';
  }
}
