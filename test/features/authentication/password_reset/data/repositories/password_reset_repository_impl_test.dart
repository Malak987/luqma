import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/authentication/password_reset/data/datasources/password_reset_remote_data_source.dart';
import 'package:luqma_app/features/authentication/password_reset/data/models/forgot_password_request_model.dart';
import 'package:luqma_app/features/authentication/password_reset/data/models/password_reset_response_model.dart';
import 'package:luqma_app/features/authentication/password_reset/data/models/reset_password_request_model.dart';
import 'package:luqma_app/features/authentication/password_reset/data/repositories/password_reset_repository_impl.dart';

void main() {
  group('PasswordResetRepositoryImpl', () {
    test('maps a successful ForgotPassword response to the entity', () async {
      final repository = PasswordResetRepositoryImpl(
        _FakeDataSource(
          forgotResult: _model(
            'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
          ),
        ),
      );

      final result = await repository.forgotPassword(
        email: 'person@example.test',
      );

      expect(
        result.message,
        'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      );
    });

    test('maps a successful ResetPassword response to the entity', () async {
      final repository = PasswordResetRepositoryImpl(
        _FakeDataSource(
          resetResult: _model('تم إعادة تعيين كلمة المرور بنجاح'),
        ),
      );

      final result = await repository.resetPassword(
        email: 'person@example.test',
        otp: '482913',
        newPassword: 'NewPassw0rd!',
      );

      expect(result.message, 'تم إعادة تعيين كلمة المرور بنجاح');
    });

    test('builds the request models from the arguments', () async {
      final dataSource = _FakeDataSource(
        forgotResult: _model('a'),
        resetResult: _model('b'),
      );
      final repository = PasswordResetRepositoryImpl(dataSource);

      await repository.forgotPassword(email: ' person@example.test ');
      await repository.resetPassword(
        email: ' person@example.test ',
        otp: ' 482913 ',
        newPassword: 'NewPassw0rd!',
      );

      expect(dataSource.forgotEmail, 'person@example.test');
      expect(dataSource.resetEmail, 'person@example.test');
      expect(dataSource.resetOtp, ' 482913 ');
      expect(dataSource.resetNewPassword, 'NewPassw0rd!');
    });

    test('keeps the whitespace-sensitive secrets untouched', () async {
      final dataSource = _FakeDataSource(resetResult: _model('b'));
      await PasswordResetRepositoryImpl(dataSource).resetPassword(
        email: 'person@example.test',
        otp: ' 482913',
        newPassword: ' spaced pass! ',
      );

      expect(dataSource.resetOtp, ' 482913');
      expect(dataSource.resetNewPassword, ' spaced pass! ',
          reason: 'trimming would change the secret the user actually set');
    });

    test('rethrows a RemoteException as a FailureException', () async {
      final repository = PasswordResetRepositoryImpl(
        _FakeDataSource(
          forgotError: const RemoteException(
            code: FailureCode.validation,
            message: 'البريد الإلكتروني غير موجود',
          ),
        ),
      );

      await expectLater(
        repository.forgotPassword(email: 'nobody@example.test'),
        throwsA(
          isA<FailureException>()
              .having((error) => error.failure.code, 'failure code',
                  FailureCode.validation)
              .having((error) => error.failure.debugMessage, 'debug message',
                  'البريد الإلكتروني غير موجود'),
        ),
      );
    });

    test(
        'converts an unexpected error into an unknown failure without '
        'echoing the raw error', () async {
      final repository = PasswordResetRepositoryImpl(
        _FakeDataSource(
          resetError: StateError('boom 482913 NewPassw0rd!'),
        ),
      );

      await expectLater(
        repository.resetPassword(
          email: 'person@example.test',
          otp: '482913',
          newPassword: 'NewPassw0rd!',
        ),
        throwsA(
          isA<FailureException>()
              .having((error) => error.failure.code, 'failure code',
                  FailureCode.unknown)
              .having(
                (error) => error.failure.debugMessage ?? '',
                'debug message',
                isNot(anyOf(contains('482913'), contains('NewPassw0rd!'))),
              ),
        ),
      );
    });

    test('rethrows a FailureException untouched', () async {
      const failure = Failure(
        FailureCode.network,
        debugMessage: 'socket closed',
      );
      final repository = PasswordResetRepositoryImpl(
        _FakeDataSource(forgotError: const FailureException(failure)),
      );

      await expectLater(
        repository.forgotPassword(email: 'person@example.test'),
        throwsA(isA<FailureException>()
            .having((error) => error.failure, 'failure', failure)),
      );
    });
  });
}

PasswordResetResponseModel _model(String message) =>
    PasswordResetResponseModel.fromEnvelope(data: '', message: message);

class _FakeDataSource implements PasswordResetRemoteDataSource {
  _FakeDataSource({
    this.forgotResult,
    this.resetResult,
    this.forgotError,
    this.resetError,
  });

  final PasswordResetResponseModel? forgotResult;
  final PasswordResetResponseModel? resetResult;
  final Object? forgotError;
  final Object? resetError;

  String? forgotEmail;
  String? resetEmail;
  String? resetOtp;
  String? resetNewPassword;

  @override
  Future<PasswordResetResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  ) async {
    forgotEmail = request.email;
    final error = forgotError;
    if (error != null) {
      throw error;
    }
    return forgotResult!;
  }

  @override
  Future<PasswordResetResponseModel> resetPassword(
    ResetPasswordRequestModel request,
  ) async {
    resetEmail = request.email;
    resetOtp = request.otp;
    resetNewPassword = request.newPassword;
    final error = resetError;
    if (error != null) {
      throw error;
    }
    return resetResult!;
  }
}
