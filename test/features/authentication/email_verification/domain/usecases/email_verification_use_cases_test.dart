import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/entities/email_verification_result.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/repositories/email_verification_repository.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/usecases/confirm_email_use_case.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/usecases/resend_otp_use_case.dart';

void main() {
  group('ConfirmEmailUseCase', () {
    test('forwards email and otp and returns the repository result', () async {
      final repository = _FakeRepository(
        const EmailVerificationResult(message: 'confirmed'),
      );

      final result = await ConfirmEmailUseCase(repository)(
        email: 'person@example.test',
        otp: '482913',
      );

      expect(result, const EmailVerificationResult(message: 'confirmed'));
      expect(repository.confirmCalls, hasLength(1));
      expect(repository.confirmCalls.single.email, 'person@example.test');
      expect(repository.confirmCalls.single.otp, '482913');
      expect(repository.resendCalls, isEmpty);
    });

    test('propagates a failure without wrapping it', () async {
      const failure = FailureException(
        Failure(FailureCode.validation, debugMessage: 'invalid code'),
      );
      final repository = _FakeRepository(null, failureException: failure);

      await expectLater(
        ConfirmEmailUseCase(repository)(
          email: 'person@example.test',
          otp: '000000',
        ),
        throwsA(same(failure)),
      );
    });
  });

  group('ResendOtpUseCase', () {
    test('forwards only the email and returns the repository result', () async {
      final repository = _FakeRepository(
        const EmailVerificationResult(message: 'resent'),
      );

      final result = await ResendOtpUseCase(repository)(
        email: 'person@example.test',
      );

      expect(result, const EmailVerificationResult(message: 'resent'));
      expect(repository.resendCalls, hasLength(1));
      expect(repository.resendCalls.single, 'person@example.test');
      expect(repository.confirmCalls, isEmpty);
    });

    test('propagates a failure without wrapping it', () async {
      const failure = FailureException(
        Failure(FailureCode.network, debugMessage: 'offline'),
      );
      final repository = _FakeRepository(null, failureException: failure);

      await expectLater(
        ResendOtpUseCase(repository)(email: 'person@example.test'),
        throwsA(same(failure)),
      );
    });
  });
}

class _Call {
  const _Call({required this.email, required this.otp});

  final String email;
  final String otp;
}

class _FakeRepository implements EmailVerificationRepository {
  _FakeRepository(this.result, {this.failureException});

  final EmailVerificationResult? result;
  final FailureException? failureException;
  final List<_Call> confirmCalls = <_Call>[];
  final List<String> resendCalls = <String>[];

  @override
  Future<EmailVerificationResult> confirmEmail({
    required String email,
    required String otp,
  }) async {
    confirmCalls.add(_Call(email: email, otp: otp));
    return _respond();
  }

  @override
  Future<EmailVerificationResult> resendOtp({required String email}) async {
    resendCalls.add(email);
    return _respond();
  }

  Future<EmailVerificationResult> _respond() async {
    if (failureException != null) {
      throw failureException!;
    }
    return result!;
  }
}
