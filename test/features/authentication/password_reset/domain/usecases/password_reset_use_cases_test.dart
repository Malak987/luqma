import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/entities/password_reset_result.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/repositories/password_reset_repository.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/usecases/forgot_password_use_case.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/usecases/reset_password_use_case.dart';

void main() {
  group('ForgotPasswordUseCase', () {
    test('forwards the email to the repository', () async {
      final repository = _FakeRepository(
        forgotResult: const PasswordResetResult(message: 'أُرسل الرمز'),
      );

      final result = await ForgotPasswordUseCase(repository).call(
        email: 'person@example.test',
      );

      expect(result.message, 'أُرسل الرمز');
      expect(repository.forgotEmail, 'person@example.test');
      expect(repository.resetCalls, 0,
          reason: 'requesting a code must not reset anything');
    });

    test('propagates a failure', () async {
      final repository = _FakeRepository(
        forgotError: const FailureException(
          Failure(FailureCode.validation,
              debugMessage: 'البريد الإلكتروني غير موجود'),
        ),
      );

      await expectLater(
        ForgotPasswordUseCase(repository).call(email: 'nobody@example.test'),
        throwsA(isA<FailureException>()),
      );
    });
  });

  group('ResetPasswordUseCase', () {
    test('forwards all three fields to the repository', () async {
      final repository = _FakeRepository(
        resetResult: const PasswordResetResult(message: 'تم التعديل'),
      );

      final result = await ResetPasswordUseCase(repository).call(
        email: 'person@example.test',
        otp: '482913',
        newPassword: 'NewPassw0rd!',
      );

      expect(result.message, 'تم التعديل');
      expect(repository.resetEmail, 'person@example.test');
      expect(repository.resetOtp, '482913');
      expect(repository.resetNewPassword, 'NewPassw0rd!');
      expect(repository.forgotCalls, 0,
          reason: 'resetting must not send another code');
    });

    test('propagates an invalid-OTP failure', () async {
      final repository = _FakeRepository(
        resetError: const FailureException(
          Failure(FailureCode.validation,
              debugMessage: 'رمز التحقق غير صحيح أو منتهي الصلاحية'),
        ),
      );

      await expectLater(
        ResetPasswordUseCase(repository).call(
          email: 'person@example.test',
          otp: '000000',
          newPassword: 'NewPassw0rd!',
        ),
        throwsA(isA<FailureException>().having(
            (error) => error.failure.debugMessage,
            'debug message',
            'رمز التحقق غير صحيح أو منتهي الصلاحية')),
      );
    });
  });
}

class _FakeRepository implements PasswordResetRepository {
  _FakeRepository({
    this.forgotResult,
    this.resetResult,
    this.forgotError,
    this.resetError,
  });

  final PasswordResetResult? forgotResult;
  final PasswordResetResult? resetResult;
  final Object? forgotError;
  final Object? resetError;

  String? forgotEmail;
  String? resetEmail;
  String? resetOtp;
  String? resetNewPassword;
  int forgotCalls = 0;
  int resetCalls = 0;

  @override
  Future<PasswordResetResult> forgotPassword({required String email}) async {
    forgotCalls++;
    forgotEmail = email;
    final error = forgotError;
    if (error != null) {
      throw error;
    }
    return forgotResult!;
  }

  @override
  Future<PasswordResetResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    resetCalls++;
    resetEmail = email;
    resetOtp = otp;
    resetNewPassword = newPassword;
    final error = resetError;
    if (error != null) {
      throw error;
    }
    return resetResult!;
  }
}
