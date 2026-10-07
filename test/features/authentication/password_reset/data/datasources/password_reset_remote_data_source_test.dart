import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/authentication/password_reset/data/datasources/password_reset_remote_data_source.dart';
import 'package:luqma_app/features/authentication/password_reset/data/models/forgot_password_request_model.dart';
import 'package:luqma_app/features/authentication/password_reset/data/models/reset_password_request_model.dart';

void main() {
  group('PasswordResetRemoteDataSourceImpl', () {
    test('sends ForgotPassword as a public request and never reads a token',
        () async {
      final storage = _FakeSecureStorageService(token: 'stale-test-token');
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final client = DioClient(storage, dio: dio);
      RequestOptions? captured;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: _forgotSuccessEnvelope(),
              ),
            );
          },
        ),
      );

      await PasswordResetRemoteDataSourceImpl(client).forgotPassword(
        const ForgotPasswordRequestModel(email: 'person@example.test'),
      );

      expect(captured, isNotNull);
      expect(captured!.path, ApiConstants.forgotPassword);
      expect(captured!.method, 'POST');
      expect(
        captured!.data,
        <String, dynamic>{'email': 'person@example.test'},
      );
      expect(
        captured!.extra[DioClient.requiresAuthenticationExtraKey],
        isFalse,
      );
      expect(
        captured!.headers.keys
            .map((key) => key.toLowerCase())
            .contains('authorization'),
        isFalse,
      );
      expect(storage.tokenReadCount, 0);
    });

    test('sends ResetPassword as a public request and never reads a token',
        () async {
      final storage = _FakeSecureStorageService(token: 'stale-test-token');
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final client = DioClient(storage, dio: dio);
      RequestOptions? captured;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: _resetSuccessEnvelope(),
              ),
            );
          },
        ),
      );

      await PasswordResetRemoteDataSourceImpl(client).resetPassword(
        const ResetPasswordRequestModel(
          email: 'person@example.test',
          otp: '482913',
          newPassword: 'NewPassw0rd!',
        ),
      );

      expect(captured!.path, ApiConstants.resetPassword);
      expect(
        captured!.data,
        <String, dynamic>{
          'email': 'person@example.test',
          'otp': '482913',
          'newPassword': 'NewPassw0rd!',
        },
      );
      expect(
        captured!.extra[DioClient.requiresAuthenticationExtraKey],
        isFalse,
      );
      expect(storage.tokenReadCount, 0);
    });

    test('parses the ForgotPassword success envelope whose data is ""',
        () async {
      final dataSource =
          _dataSourceReturning(statusCode: 200, body: _forgotSuccessEnvelope());

      final result = await dataSource.forgotPassword(
        const ForgotPasswordRequestModel(email: 'person@example.test'),
      );

      expect(
        result.message,
        'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      );
      expect(result.payload, '');
      expect(result.carriesToken, isFalse);
    });

    test(
        'maps an unknown email (HTTP 400) to the validation code and keeps '
        'the Arabic message', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'message': 'البريد الإلكتروني غير موجود',
          'data': null,
          'isSucceeded': false,
          'timestamp': '2026-10-07T07:55:01.0000000Z',
        },
      );

      await expectLater(
        dataSource.forgotPassword(
          const ForgotPasswordRequestModel(email: 'nobody@example.test'),
        ),
        throwsA(
          isA<RemoteException>()
              .having(
                  (error) => error.code, 'failure code', FailureCode.validation)
              .having((error) => error.message, 'backend message',
                  'البريد الإلكتروني غير موجود'),
        ),
      );
    });

    test('maps an invalid/expired OTP (HTTP 400) to the validation code',
        () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'message': 'رمز التحقق غير صحيح أو منتهي الصلاحية',
          'data': null,
          'isSucceeded': false,
        },
      );

      await expectLater(
        dataSource.resetPassword(
          const ResetPasswordRequestModel(
            email: 'person@example.test',
            otp: '000000',
            newPassword: 'NewPassw0rd!',
          ),
        ),
        throwsA(
          isA<RemoteException>()
              .having(
                  (error) => error.code, 'failure code', FailureCode.validation)
              .having((error) => error.message, 'backend message',
                  'رمز التحقق غير صحيح أو منتهي الصلاحية'),
        ),
      );
    });

    test('maps a ProblemDetails body on the newPassword field', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
          'title': 'One or more validation errors occurred.',
          'status': 400,
          'errors': <String, dynamic>{
            '\$.newPassword': <dynamic>['كلمة المرور قصيرة جدًا'],
          },
        },
      );

      await expectLater(
        dataSource.resetPassword(
          const ResetPasswordRequestModel(
            email: 'person@example.test',
            otp: '482913',
            newPassword: '1',
          ),
        ),
        throwsA(
          isA<RemoteException>()
              .having(
                  (error) => error.code, 'failure code', FailureCode.validation)
              .having((error) => error.message, 'backend message',
                  contains('كلمة المرور قصيرة جدًا')),
        ),
      );
    });

    test('maps HTTP 401 to invalid credentials', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 401,
        body: <String, dynamic>{'message': 'غير مصرح'},
      );

      await expectLater(
        dataSource.forgotPassword(
          const ForgotPasswordRequestModel(email: 'person@example.test'),
        ),
        throwsA(
          isA<RemoteException>().having((error) => error.code, 'failure code',
              FailureCode.invalidCredentials),
        ),
      );
    });

    test('maps an empty error body to the unknown code', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 500,
        body: const <String, dynamic>{},
      );

      await expectLater(
        dataSource.forgotPassword(
          const ForgotPasswordRequestModel(email: 'person@example.test'),
        ),
        throwsA(isA<RemoteException>().having(
            (error) => error.code, 'failure code', FailureCode.unknown)),
      );
    });

    test('maps a network failure to the network code', () async {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final client = DioClient(_FakeSecureStorageService(), dio: dio);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
                error: 'timeout',
              ),
            );
          },
        ),
      );

      await expectLater(
        PasswordResetRemoteDataSourceImpl(client).forgotPassword(
          const ForgotPasswordRequestModel(email: 'person@example.test'),
        ),
        throwsA(isA<RemoteException>().having(
            (error) => error.code, 'failure code', FailureCode.network)),
      );
    });

    test('maps a cancelled request to the unknown code', () async {
      final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final client = DioClient(_FakeSecureStorageService(), dio: dio);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
              ),
            );
          },
        ),
      );

      await expectLater(
        PasswordResetRemoteDataSourceImpl(client).resetPassword(
          const ResetPasswordRequestModel(
            email: 'person@example.test',
            otp: '482913',
            newPassword: 'NewPassw0rd!',
          ),
        ),
        throwsA(isA<RemoteException>().having(
            (error) => error.code, 'failure code', FailureCode.unknown)),
      );
    });

    test('never leaks the OTP or password in an error message', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 500,
        body: const <String, dynamic>{},
      );

      await expectLater(
        dataSource.resetPassword(
          const ResetPasswordRequestModel(
            email: 'person@example.test',
            otp: '482913',
            newPassword: 'NewPassw0rd!',
          ),
        ),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.message ?? '',
            'message',
            isNot(anyOf(contains('482913'), contains('NewPassw0rd!'))),
          ),
        ),
      );
    });
  });
}

/// The exact body captured from a live ForgotPassword call.
Map<String, dynamic> _forgotSuccessEnvelope() => <String, dynamic>{
      'message': 'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      'data': '',
      'isSucceeded': true,
      'timestamp': '2026-10-07T07:51:38.8052911Z',
    };

/// ResetPassword's success body is unverified (a valid OTP is needed); the
/// shape is inferred from every other envelope in the Account controller.
Map<String, dynamic> _resetSuccessEnvelope() => <String, dynamic>{
      'message': 'تم إعادة تعيين كلمة المرور بنجاح',
      'data': '',
      'isSucceeded': true,
      'timestamp': '2026-10-07T07:51:38.8052911Z',
    };

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.token}) : super(const FlutterSecureStorage());

  final String? token;
  int tokenReadCount = 0;

  @override
  Future<String?> getToken() async {
    tokenReadCount++;
    return token;
  }
}

PasswordResetRemoteDataSourceImpl _dataSourceReturning({
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

  return PasswordResetRemoteDataSourceImpl(client);
}
