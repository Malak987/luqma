import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/authentication/register/data/datasources/register_remote_data_source.dart';
import 'package:luqma_app/features/authentication/register/data/models/register_request_model.dart';

void main() {
  group('RegisterRemoteDataSourceImpl', () {
    test('posts the contract payload as a public request without a token',
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
                data: _successfulEnvelope(),
              ),
            );
          },
        ),
      );

      final dataSource = RegisterRemoteDataSourceImpl(client);
      final result = await dataSource.register(_request());

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.path, ApiConstants.register);
      expect(
        capturedRequest!.data,
        <String, dynamic>{
          'userName': 'new_user',
          'email': 'person@example.test',
          'password': 'not-a-real-password',
          'confirmPassword': 'not-a-real-password',
          'phoneNumber': '01000000000',
          'address': '1 Test Street',
          'role': 0,
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
      expect(result.message, 'تم التسجيل بنجاح، برجاء تأكيد البريد الإلكتروني');
    });

    test('surfaces the backend message from a successful envelope', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 200,
        body: _successfulEnvelope(),
      );

      final result = await dataSource.register(_request());

      expect(result.message, 'تم التسجيل بنجاح، برجاء تأكيد البريد الإلكتروني');
    });

    test('maps duplicate email (HTTP 400) to the validation failure code',
        () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'message': 'هذا البريد مستخدم بالفعل',
          'data': null,
          'isSucceeded': false,
          'timestamp': '2027-08-06T12:25:06Z',
        },
      );

      await expectLater(
        dataSource.register(_request()),
        throwsA(
          isA<RemoteException>()
              .having(
                (error) => error.code,
                'failure code',
                FailureCode.validation,
              )
              .having(
                (error) => error.message,
                'message',
                'هذا البريد مستخدم بالفعل',
              ),
        ),
      );
    });

    test('surfaces weak-password details from a rejected envelope', () async {
      const backendMessage =
          'خطأ في التسجيل: Passwords must be at least 6 characters., '
          'Passwords must have at least one digit (\'0\'-\'9\').';
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'message': backendMessage,
          'data': null,
          'isSucceeded': false,
        },
      );

      await expectLater(
        dataSource.register(_request()),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.message,
            'message',
            backendMessage,
          ),
        ),
      );
    });

    test('maps the forbidden role rejection to the validation failure code',
        () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'message': 'لا يمكن التسجيل بهذه الصلاحية',
          'data': null,
          'isSucceeded': false,
        },
      );

      await expectLater(
        dataSource.register(_request()),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'failure code',
            FailureCode.validation,
          ),
        ),
      );
    });

    test('recovers a message from an ASP.NET ProblemDetails body', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
          'title': 'One or more validation errors occurred.',
          'status': 400,
          'errors': <String, dynamic>{
            r'$': <String>["'not-json' is an invalid JSON literal."],
            'request': <String>['The request field is required.'],
          },
          'traceId': '00-trace',
        },
      );

      await expectLater(
        dataSource.register(_request()),
        throwsA(
          isA<RemoteException>()
              .having(
                (error) => error.code,
                'failure code',
                FailureCode.validation,
              )
              .having(
                (error) => error.message,
                'message',
                contains('The request field is required.'),
              ),
        ),
      );
    });

    test('falls back to a generic message when the body carries none',
        () async {
      final dataSource = _dataSourceReturning(
        statusCode: 500,
        body: <String, dynamic>{'unexpected': true},
      );

      await expectLater(
        dataSource.register(_request()),
        throwsA(
          isA<RemoteException>()
              .having(
                (error) => error.code,
                'failure code',
                FailureCode.unknown,
              )
              .having(
                (error) => error.message,
                'message',
                'Register request failed',
              ),
        ),
      );
    });

    test('maps a connection error to the network failure code', () async {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final client = DioClient(_FakeSecureStorageService(), dio: dio);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      await expectLater(
        RegisterRemoteDataSourceImpl(client).register(_request()),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'failure code',
            FailureCode.network,
          ),
        ),
      );
    });

    test('maps a malformed successful envelope to an unknown remote failure',
        () async {
      // `data` must be a string; an object means the contract changed.
      final dataSource = _dataSourceReturning(
        statusCode: 200,
        body: <String, dynamic>{
          'isSucceeded': true,
          'data': <String, dynamic>{'token': 'unexpected'},
        },
      );

      await expectLater(
        dataSource.register(_request()),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'failure code',
            FailureCode.unknown,
          ),
        ),
      );
    });
  });
}

RegisterRequestModel _request() => const RegisterRequestModel(
      userName: 'new_user',
      email: 'person@example.test',
      password: 'not-a-real-password',
      confirmPassword: 'not-a-real-password',
      phoneNumber: '01000000000',
      address: '1 Test Street',
    );

RegisterRemoteDataSourceImpl _dataSourceReturning({
  required int statusCode,
  required Object body,
}) {
  final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final client = DioClient(_FakeSecureStorageService(), dio: dio);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (statusCode >= 400) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: statusCode,
                data: body,
              ),
            ),
          );
          return;
        }
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: body,
          ),
        );
      },
    ),
  );

  return RegisterRemoteDataSourceImpl(client);
}

Map<String, dynamic> _successfulEnvelope() => <String, dynamic>{
      'message': 'تم التسجيل بنجاح، برجاء تأكيد البريد الإلكتروني',
      'data': 'تم التسجيل بنجاح، برجاء تأكيد البريد الإلكتروني',
      'isSucceeded': true,
      'timestamp': '2027-08-06T12:25:06.4627977Z',
    };

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.token})
      : super(const FlutterSecureStorage());

  final String? token;
  int tokenReadCount = 0;

  @override
  Future<String?> getToken() async {
    tokenReadCount++;
    return token;
  }
}
