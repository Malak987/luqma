import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/home/data/datasources/main_category_remote_data_source.dart';

import '../../support/main_category_fixtures.dart';

void main() {
  group('MainCategoryRemoteDataSourceImpl', () {
    test('uses the shared client for the public GetAll GET request', () async {
      final harness = _Harness(
        responseData: mainCategoryEnvelope(data: <Object?>[mainCategoryJson()]),
      );

      final result = await harness.dataSource.getAllMainCategories();

      expect(result.single.id, mainCategoryId);
      expect(harness.request?.method, 'GET');
      expect(harness.request?.path, ApiConstants.getAllMainCategories);
      expect(harness.request?.uri.toString(),
          'https://luqma-api.runasp.net/api/MainCategory/GetAll');
      expect(harness.request?.data, isNull);
      expect(harness.request?.queryParameters, isEmpty);
      expect(harness.request?.headers.containsKey('Authorization'), isFalse);
      expect(harness.request?.extra[DioClient.requiresAuthenticationExtraKey],
          isNot(true));
      expect(harness.storage.tokenReads, 0);
    });

    test('parses multiple categories without dropping inactive entries in data',
        () async {
      final harness = _Harness(
        responseData: mainCategoryEnvelope(data: <Object?>[
          mainCategoryJson(id: 'first', displayOrder: 3),
          mainCategoryJson(id: 'second', displayOrder: 1, isActive: false),
        ]),
      );

      final result = await harness.dataSource.getAllMainCategories();

      expect(
          result.map((category) => category.id), <String>['first', 'second']);
      expect(result.last.isActive, isFalse);
      expect(result.first.nameAr, 'مطاعم');
      expect(result.first.nameEn, 'Restaurants');
    });

    test('accepts an empty successful list', () async {
      final harness =
          _Harness(responseData: mainCategoryEnvelope(data: <Object?>[]));

      expect(await harness.dataSource.getAllMainCategories(), isEmpty);
    });

    test('maps an unsuccessful envelope to an API failure, not an empty list',
        () async {
      final harness = _Harness(
        responseData: mainCategoryEnvelope(
          data: null,
          isSucceeded: false,
          message: '  Request rejected  ',
        ),
      );

      await expectLater(
        harness.dataSource.getAllMainCategories(),
        throwsA(isA<RemoteException>()
            .having((error) => error.code, 'code', FailureCode.validation)
            .having((error) => error.message, 'message', 'Request rejected')),
      );
    });

    test('supplies a diagnostic fallback for an empty API error message',
        () async {
      final harness = _Harness(
        responseData:
            mainCategoryEnvelope(data: null, isSucceeded: false, message: '  '),
      );

      await expectLater(
        harness.dataSource.getAllMainCategories(),
        throwsA(isA<RemoteException>().having(
          (error) => error.message,
          'message',
          'MainCategory GetAll request was not successful',
        )),
      );
    });

    test('maps unexpected envelopes, data and entries to parsing failures',
        () async {
      final malformedResponses = <Object?>[
        null,
        'not JSON',
        <Object?>[],
        mainCategoryEnvelope(data: null),
        mainCategoryEnvelope(data: <String, Object?>{}),
        mainCategoryEnvelope(data: 'not a list'),
        mainCategoryEnvelope(data: <Object?>[])..remove('data'),
        mainCategoryEnvelope(data: <Object?>[])..['isSucceeded'] = 'true',
        mainCategoryEnvelope(data: <Object?>[null]),
        mainCategoryEnvelope(data: <Object?>[1]),
        mainCategoryEnvelope(
            data: <Object?>[mainCategoryJson()..remove('nameAr')]),
        mainCategoryEnvelope(
            data: <Object?>[mainCategoryJson()..['isActive'] = 'true']),
      ];
      for (final response in malformedResponses) {
        final harness = _Harness(responseData: response);
        await expectLater(
          harness.dataSource.getAllMainCategories(),
          throwsA(isA<RemoteException>()
              .having((error) => error.code, 'code', FailureCode.unknown)
              .having((error) => error.message, 'message',
                  'Invalid MainCategory GetAll response')),
        );
      }
    });

    for (final type in <DioExceptionType>[
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.badCertificate,
    ]) {
      test('maps $type to the existing network failure code', () async {
        await expectLater(
          _Harness(failureType: type).dataSource.getAllMainCategories(),
          throwsA(isA<RemoteException>()
              .having((error) => error.code, 'code', FailureCode.network)),
        );
      });
    }

    for (final entry in <int, FailureCode>{
      400: FailureCode.validation,
      401: FailureCode.invalidCredentials,
      403: FailureCode.invalidCredentials,
      500: FailureCode.unknown,
    }.entries) {
      test('maps HTTP ${entry.key} and retains the server error message',
          () async {
        final harness = _Harness(
          failureType: DioExceptionType.badResponse,
          statusCode: entry.key,
          responseData: <String, dynamic>{'message': '  Server failure  '},
        );
        await expectLater(
          harness.dataSource.getAllMainCategories(),
          throwsA(isA<RemoteException>()
              .having((error) => error.code, 'code', entry.value)
              .having((error) => error.message, 'message', 'Server failure')),
        );
      });
    }

    test('handles a non-JSON HTTP error body safely', () async {
      await expectLater(
        _Harness(
          failureType: DioExceptionType.badResponse,
          statusCode: 502,
          responseData: '<html>Unavailable</html>',
        ).dataSource.getAllMainCategories(),
        throwsA(isA<RemoteException>()
            .having((error) => error.code, 'code', FailureCode.unknown)
            .having((error) => error.message, 'message',
                'MainCategory GetAll request failed')),
      );
    });

    for (final type in <DioExceptionType>[
      DioExceptionType.cancel,
      DioExceptionType.unknown,
    ]) {
      test('maps $type to the existing unknown failure code', () async {
        await expectLater(
          _Harness(failureType: type).dataSource.getAllMainCategories(),
          throwsA(isA<RemoteException>()
              .having((error) => error.code, 'code', FailureCode.unknown)),
        );
      });
    }
  });
}

/// Interceptors resolve/reject every request before an HTTP adapter runs.
class _Harness {
  _Harness(
      {Object? responseData, DioExceptionType? failureType, int? statusCode}) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: <String, dynamic>{'Authorization': 'Bearer stale'},
    ));
    addTearDown(() => dio.close(force: true));
    final client = DioClient(storage, dio: dio);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      request = options;
      if (failureType != null) {
        handler.reject(DioException(
          requestOptions: options,
          type: failureType,
          response: statusCode == null
              ? null
              : Response<dynamic>(
                  requestOptions: options,
                  statusCode: statusCode,
                  data: responseData),
        ));
      } else {
        handler.resolve(Response<dynamic>(
            requestOptions: options, statusCode: 200, data: responseData));
      }
    }));
    dataSource = MainCategoryRemoteDataSourceImpl(client);
  }

  final storage = _FakeSecureStorageService();
  late final MainCategoryRemoteDataSourceImpl dataSource;
  RequestOptions? request;
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(const FlutterSecureStorage());

  int tokenReads = 0;

  @override
  Future<String?> getToken() async {
    tokenReads++;
    return 'test-token';
  }
}
