import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/authentication/email_verification/data/datasources/email_verification_remote_data_source.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/confirm_email_request_model.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/resend_otp_request_model.dart';

void main() {
  group('EmailVerificationRemoteDataSourceImpl', () {
    test('sends ConfirmEmail as a public request and never reads a token',
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
                data: _resendSuccessEnvelope(),
              ),
            );
          },
        ),
      );

      await EmailVerificationRemoteDataSourceImpl(client).confirmEmail(
        const ConfirmEmailRequestModel(
          email: 'person@example.test',
          otp: '482913',
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.path, ApiConstants.confirmEmail);
      expect(
        captured!.data,
        <String, dynamic>{
          'email': 'person@example.test',
          'otp': '482913',
        },
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

    test('sends ResendOtp as a public request and never reads a token',
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
                data: _resendSuccessEnvelope(),
              ),
            );
          },
        ),
      );

      await EmailVerificationRemoteDataSourceImpl(client).resendOtp(
        const ResendOtpRequestModel(email: 'person@example.test'),
      );

      expect(captured!.path, ApiConstants.resendOtp);
      expect(captured!.data, <String, dynamic>{'email': 'person@example.test'});
      expect(
        captured!.extra[DioClient.requiresAuthenticationExtraKey],
        isFalse,
      );
      expect(storage.tokenReadCount, 0);
    });

    test('parses the ResendOtp success envelope whose data is ""', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 200,
        body: _resendSuccessEnvelope(),
      );

      final result = await dataSource.resendOtp(
        const ResendOtpRequestModel(email: 'person@example.test'),
      );

      expect(result.message, 'تم إعادة إرسال رمز التحقق بنجاح');
      expect(result.payload, '');
      expect(result.carriesToken, isFalse);
    });

    test('maps an invalid/expired OTP (HTTP 400) to the validation code and '
        'keeps the Arabic message', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'message': 'رمز التحقق غير صحيح أو منتهي الصلاحية',
          'data': null,
          'isSucceeded': false,
          'timestamp': '2026-10-06T20:54:12.9592851Z',
        },
      );

      await expectLater(
        dataSource.confirmEmail(
          const ConfirmEmailRequestModel(
            email: 'person@example.test',
            otp: '000000',
          ),
        ),
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
                'رمز التحقق غير صحيح أو منتهي الصلاحية',
              ),
        ),
      );
    });

    test('maps the ResendOtp "user does not exist" rejection', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'message': 'المستخدم غير موجود',
          'data': null,
          'isSucceeded': false,
        },
      );

      await expectLater(
        dataSource.resendOtp(
          const ResendOtpRequestModel(email: 'nobody@example.test'),
        ),
        throwsA(
          isA<RemoteException>()
              .having((e) => e.code, 'code', FailureCode.validation)
              .having((e) => e.message, 'message', 'المستخدم غير موجود'),
        ),
      );
    });

    test('recovers a message from a PascalCase ProblemDetails body', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 400,
        body: <String, dynamic>{
          'errors': <String, dynamic>{
            'Otp': <String>['The Otp field is required.'],
          },
          'traceId': '00-trace',
        },
      );

      await expectLater(
        dataSource.confirmEmail(
          const ConfirmEmailRequestModel(email: 'person@example.test', otp: ''),
        ),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.message,
            'message',
            contains('The Otp field is required.'),
          ),
        ),
      );
    });

    test('maps a connection error to the network code', () async {
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
        EmailVerificationRemoteDataSourceImpl(client).confirmEmail(
          const ConfirmEmailRequestModel(
            email: 'person@example.test',
            otp: '482913',
          ),
        ),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'failure code',
            FailureCode.network,
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
        dataSource.confirmEmail(
          const ConfirmEmailRequestModel(
            email: 'person@example.test',
            otp: '482913',
          ),
        ),
        throwsA(
          isA<RemoteException>()
              .having((e) => e.code, 'code', FailureCode.unknown)
              .having(
                (e) => e.message,
                'message',
                'Confirm email request failed',
              ),
        ),
      );
    });

    test('maps a malformed successful envelope to an unknown remote failure',
        () async {
      final dataSource = _dataSourceReturning(
        statusCode: 200,
        body: <String, dynamic>{
          'isSucceeded': 'true',
          'data': '',
        },
      );

      await expectLater(
        dataSource.confirmEmail(
          const ConfirmEmailRequestModel(
            email: 'person@example.test',
            otp: '482913',
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

    test('honours a 200 that still reports failure', () async {
      final dataSource = _dataSourceReturning(
        statusCode: 200,
        body: <String, dynamic>{
          'message': 'رمز التحقق غير صحيح أو منتهي الصلاحية',
          'isSucceeded': false,
        },
      );

      await expectLater(
        dataSource.confirmEmail(
          const ConfirmEmailRequestModel(
            email: 'person@example.test',
            otp: '482913',
          ),
        ),
        throwsA(
          isA<RemoteException>().having(
            (error) => error.code,
            'failure code',
            FailureCode.validation,
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _resendSuccessEnvelope() => <String, dynamic>{
      'message': 'تم إعادة إرسال رمز التحقق بنجاح',
      'data': '',
      'isSucceeded': true,
      'timestamp': '2026-10-06T20:54:42.7743688Z',
    };

EmailVerificationRemoteDataSourceImpl _dataSourceReturning({
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

  return EmailVerificationRemoteDataSourceImpl(client);
}

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
