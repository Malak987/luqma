import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/authentication/login/data/datasources/login_remote_data_source.dart';
import 'package:luqma_app/features/authentication/login/data/models/login_request_model.dart';

void main() {
  group('LoginRemoteDataSourceImpl', () {
    test('constructs the API request and omits a stale bearer token', () async {
      final storage = _FakeSecureStorageService(token: 'stale-test-token');
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final client = DioClient(storage, dio: dio);
      RequestOptions? capturedRequest;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: _successfulEnvelope(),
              ),
            );
          },
        ),
      );

      final dataSource = LoginRemoteDataSourceImpl(client);
      await dataSource.login(
        const LoginRequestModel(
          email: 'person@example.test',
          password: 'not-a-real-password',
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.path, ApiConstants.login);
      expect(
        capturedRequest!.data,
        <String, dynamic>{
          'email': 'person@example.test',
          'password': 'not-a-real-password',
        },
      );
      expect(
        capturedRequest!.extra[DioClient.requiresAuthenticationExtraKey],
        isFalse,
      );
      expect(
        capturedRequest!.headers.keys
            .map((key) => key.toLowerCase())
            .contains('authorization'),
        isFalse,
      );
      expect(storage.tokenReadCount, 0);
    });

    test('attaches a token only when a request opts into authentication',
        () async {
      final storage = _FakeSecureStorageService(token: 'stale-test-token');
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final client = DioClient(storage, dio: dio);
      RequestOptions? capturedRequest;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedRequest = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
              ),
            );
          },
        ),
      );

      await client.dio.get<Object?>(
        '/api/protected-resource',
        options: Options(
          extra: <String, dynamic>{
            DioClient.requiresAuthenticationExtraKey: true,
          },
        ),
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.headers['Authorization'],
        'Bearer stale-test-token',
      );
      expect(storage.tokenReadCount, 1);
    });

    test('maps HTTP 401 to the existing invalid-credentials failure', () async {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final client = DioClient(
        _FakeSecureStorageService(),
        dio: dio,
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 401,
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );
      final dataSource = LoginRemoteDataSourceImpl(client);

      await expectLater(
        dataSource.login(
          const LoginRequestModel(
            email: 'person@example.test',
            password: 'not-a-real-password',
          ),
        ),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'failure code',
            FailureCode.invalidCredentials,
          ),
        ),
      );
    });

    test('maps an unsuccessful API envelope without parsing its message',
        () async {
      final dataSource = _dataSourceReturning(<String, dynamic>{
        'message': 'An API-provided failure message',
        'isSucceeded': false,
        'data': null,
      });

      await expectLater(
        dataSource.login(
          const LoginRequestModel(
            email: 'person@example.test',
            password: 'not-a-real-password',
          ),
        ),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'failure code',
            FailureCode.unknown,
          ),
        ),
      );
    });

    test('maps a malformed successful envelope to a remote failure', () async {
      final dataSource = _dataSourceReturning(<String, dynamic>{
        'isSucceeded': true,
        'data': <String, dynamic>{'userId': 'user-123'},
      });

      await expectLater(
        dataSource.login(
          const LoginRequestModel(
            email: 'person@example.test',
            password: 'not-a-real-password',
          ),
        ),
        throwsA(isA<RemoteException>()),
      );
    });
  });
}

LoginRemoteDataSourceImpl _dataSourceReturning(Object responseData) {
  final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final client = DioClient(
    _FakeSecureStorageService(),
    dio: dio,
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
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

  return LoginRemoteDataSourceImpl(client);
}

Map<String, dynamic> _successfulEnvelope() => <String, dynamic>{
      'message': 'Login succeeded',
      'data': <String, dynamic>{
        'userId': 'user-123',
        'userName': 'Test User',
        'role': 'User',
        'token': 'test-token-not-real',
        'expiresAt': '2027-08-06T12:25:06.4627977Z',
      },
      'isSucceeded': true,
      'timestamp': '2027-08-06T12:25:06Z',
    };

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.token}) : super(FlutterSecureStorage());

  final String? token;
  int tokenReadCount = 0;

  @override
  Future<String?> getToken() async {
    tokenReadCount++;
    return token;
  }
}
