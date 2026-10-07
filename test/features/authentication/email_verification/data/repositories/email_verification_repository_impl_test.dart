import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/authentication/email_verification/data/datasources/email_verification_remote_data_source.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/confirm_email_request_model.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/email_verification_response_model.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/resend_otp_request_model.dart';
import 'package:luqma_app/features/authentication/email_verification/data/repositories/email_verification_repository_impl.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/entities/email_verification_result.dart';

void main() {
  group('EmailVerificationRepositoryImpl', () {
    test('trims the email but sends the OTP verbatim', () async {
      final remote = _FakeRemote(
        const EmailVerificationResponseModel(message: 'confirmed'),
      );

      final result = await EmailVerificationRepositoryImpl(remote).confirmEmail(
        email: '  person@example.test  ',
        otp: ' 482913 ',
      );

      expect(result, const EmailVerificationResult(message: 'confirmed'));
      expect(remote.confirmRequest?.email, 'person@example.test');
      expect(remote.confirmRequest?.otp, ' 482913 ');
    });

    test('maps the resend response to the domain result', () async {
      final remote = _FakeRemote(
        const EmailVerificationResponseModel(
          message: 'تم إعادة إرسال رمز التحقق بنجاح',
        ),
      );

      final result = await EmailVerificationRepositoryImpl(remote).resendOtp(
        email: '  person@example.test  ',
      );

      expect(
        result,
        const EmailVerificationResult(
          message: 'تم إعادة إرسال رمز التحقق بنجاح',
        ),
      );
      expect(remote.resendRequest?.email, 'person@example.test');
      expect(remote.confirmRequest, isNull);
    });

    test('maps a remote failure and keeps the backend message', () async {
      final remote = _FakeRemote(
        null,
        remoteException: const RemoteException(
          code: FailureCode.validation,
          message: 'رمز التحقق غير صحيح أو منتهي الصلاحية',
        ),
      );

      await expectLater(
        EmailVerificationRepositoryImpl(remote).confirmEmail(
          email: 'person@example.test',
          otp: '000000',
        ),
        throwsA(
          isA<FailureException>()
              .having(
                (error) => error.failure.code,
                'failure code',
                FailureCode.validation,
              )
              .having(
                (error) => error.failure.debugMessage,
                'debug message',
                'رمز التحقق غير صحيح أو منتهي الصلاحية',
              ),
        ),
      );
    });

    test('maps a resend network failure to the network code', () async {
      final remote = _FakeRemote(
        null,
        remoteException: const RemoteException(
          code: FailureCode.network,
          message: 'Network request failed',
        ),
      );

      await expectLater(
        EmailVerificationRepositoryImpl(remote)
            .resendOtp(email: 'person@example.test'),
        throwsA(
          isA<FailureException>().having(
            (error) => error.failure.code,
            'failure code',
            FailureCode.network,
          ),
        ),
      );
    });

    test('rethrows an existing FailureException untouched', () async {
      const original = FailureException(
        Failure(FailureCode.invalidCredentials, debugMessage: 'original'),
      );
      final remote = _FakeRemote(null, failureException: original);

      await expectLater(
        EmailVerificationRepositoryImpl(remote)
            .confirmEmail(email: 'person@example.test', otp: '482913'),
        throwsA(same(original)),
      );
    });

    test('converts an unexpected error without leaking the OTP', () async {
      final remote = _FakeRemote(
        null,
        unexpectedError: StateError('boom with 482913 inside'),
      );

      await expectLater(
        EmailVerificationRepositoryImpl(remote).confirmEmail(
          email: 'person@example.test',
          otp: '482913',
        ),
        throwsA(
          isA<FailureException>()
              .having(
                (error) => error.failure.code,
                'failure code',
                FailureCode.unknown,
              )
              .having(
                (error) => error.failure.debugMessage,
                'debug message',
                isNot(contains('482913')),
              ),
        ),
      );
    });
  });
}

class _FakeRemote implements EmailVerificationRemoteDataSource {
  _FakeRemote(
    this.response, {
    this.remoteException,
    this.failureException,
    this.unexpectedError,
  });

  final EmailVerificationResponseModel? response;
  final RemoteException? remoteException;
  final FailureException? failureException;
  final Object? unexpectedError;
  ConfirmEmailRequestModel? confirmRequest;
  ResendOtpRequestModel? resendRequest;

  @override
  Future<EmailVerificationResponseModel> confirmEmail(
    ConfirmEmailRequestModel request,
  ) async {
    confirmRequest = request;
    return _respond();
  }

  @override
  Future<EmailVerificationResponseModel> resendOtp(
    ResendOtpRequestModel request,
  ) async {
    resendRequest = request;
    return _respond();
  }

  Future<EmailVerificationResponseModel> _respond() async {
    if (remoteException != null) {
      throw remoteException!;
    }
    if (failureException != null) {
      throw failureException!;
    }
    if (unexpectedError != null) {
      throw unexpectedError!;
    }
    return response!;
  }
}
