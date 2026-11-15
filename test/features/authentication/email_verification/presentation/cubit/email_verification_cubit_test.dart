import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/entities/email_verification_result.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/repositories/email_verification_repository.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/usecases/confirm_email_use_case.dart';
import 'package:luqma_app/features/authentication/email_verification/domain/usecases/resend_otp_use_case.dart';
import 'package:luqma_app/features/authentication/email_verification/presentation/cubit/email_verification_cubit.dart';
import 'package:luqma_app/features/authentication/email_verification/presentation/cubit/email_verification_state.dart';

void main() {
  const email = 'person@example.test';

  group('EmailVerificationCubit.confirm', () {
    test('emits confirming then confirmed with the backend message', () async {
      final repository = _FakeRepository(
        const EmailVerificationResult(message: 'تم التأكيد بنجاح'),
      );
      final cubit = _cubit(repository, clock: _FakeClock());

      final future = cubit.confirm(email: email, otp: '482913');
      expect(cubit.state.isConfirming, isTrue);
      expect(cubit.state.isBusy, isTrue);
      await future;

      expect(cubit.state.isConfirmed, isTrue);
      expect(cubit.state.message, 'تم التأكيد بنجاح');
      expect(cubit.state.lastAction, EmailVerificationAction.confirm);
      expect(cubit.state.failure, isNull);
    });

    test('emits a validation failure and keeps the backend message', () async {
      final repository = _FakeRepository(
        null,
        failureException: const FailureException(
          Failure(
            FailureCode.validation,
            debugMessage: 'رمز التحقق غير صحيح أو منتهي الصلاحية',
          ),
        ),
      );
      final cubit = _cubit(repository, clock: _FakeClock());

      await cubit.confirm(email: email, otp: '000000');

      expect(cubit.state.hasFailure, isTrue);
      expect(cubit.state.failure?.code, FailureCode.validation);
      expect(
        cubit.state.failure?.debugMessage,
        'رمز التحقق غير صحيح أو منتهي الصلاحية',
      );
      expect(cubit.state.failedAction, EmailVerificationAction.confirm);
      expect(cubit.state.message, isNull);
    });

    test('emits a network failure unchanged', () async {
      final repository = _FakeRepository(
        null,
        failureException: const FailureException(
          Failure(FailureCode.network, debugMessage: 'Network request failed'),
        ),
      );
      final cubit = _cubit(repository, clock: _FakeClock());

      await cubit.confirm(email: email, otp: '482913');

      expect(cubit.state.failure?.code, FailureCode.network);
    });

    test('ignores a duplicate submission while confirming', () async {
      final repository = _FakeRepository(
        const EmailVerificationResult(message: 'confirmed'),
      );
      final cubit = _cubit(repository, clock: _FakeClock());

      final first = cubit.confirm(email: email, otp: '482913');
      final second = cubit.confirm(email: email, otp: '482913');
      await Future.wait(<Future<void>>[first, second]);

      expect(repository.confirmCalls, hasLength(1));
    });

    test('does not leak a thrown error into the failure message', () async {
      final repository = _FakeRepository(
        null,
        unexpectedError: StateError('boom with 482913 inside'),
      );
      final cubit = _cubit(repository, clock: _FakeClock());

      await cubit.confirm(email: email, otp: '482913');

      expect(cubit.state.failure?.code, FailureCode.unknown);
      expect(cubit.state.failure?.debugMessage, isNot(contains('482913')));
    });
  });

  group('EmailVerificationCubit.resend', () {
    test('emits isResending then reports the backend message', () async {
      final clock = _FakeClock();
      final repository = _FakeRepository(
        const EmailVerificationResult(
          message: 'تم إعادة إرسال رمز التحقق بنجاح',
        ),
      );
      final cubit = _cubit(repository, clock: clock);
      clock.advance(const Duration(seconds: 61));

      expect(cubit.canResend, isTrue);
      final future = cubit.resend(email: email);
      expect(cubit.state.isResending, isTrue);
      expect(cubit.state.status, EmailVerificationStatus.initial);
      await future;

      expect(cubit.state.isResending, isFalse);
      expect(cubit.state.message, 'تم إعادة إرسال رمز التحقق بنجاح');
      expect(cubit.state.lastAction, EmailVerificationAction.resend);
      expect(cubit.state.hasFailure, isFalse);
    });

    test('reports a resend failure without wiping the form state', () async {
      final clock = _FakeClock();
      final repository = _FakeRepository(
        null,
        failureException: const FailureException(
          Failure(
            FailureCode.validation,
            debugMessage: 'المستخدم غير موجود',
          ),
        ),
      );
      final cubit = _cubit(repository, clock: clock);
      clock.advance(const Duration(seconds: 61));

      await cubit.resend(email: email);

      expect(cubit.state.isResending, isFalse);
      expect(cubit.state.failure?.debugMessage, 'المستخدم غير موجود');
      expect(cubit.state.failedAction, EmailVerificationAction.resend);
      expect(cubit.state.isConfirmed, isFalse);
    });

    test('ignores a duplicate submission while resending', () async {
      final clock = _FakeClock();
      final repository = _FakeRepository(
        const EmailVerificationResult(message: 'resent'),
      );
      final cubit = _cubit(repository, clock: clock);
      clock.advance(const Duration(seconds: 61));

      final first = cubit.resend(email: email);
      final second = cubit.resend(email: email);
      await Future.wait(<Future<void>>[first, second]);

      expect(repository.resendCalls, hasLength(1));
    });
  });

  group('EmailVerificationCubit resend cooldown', () {
    test('starts at 60 seconds because Register already sent the first code',
        () {
      final cubit = _cubit(_FakeRepository(null), clock: _FakeClock());

      expect(cubit.resendCooldownRemaining, 60);
      expect(cubit.canResend, isFalse);
    });

    test('counts down and re-enables resend after 60 seconds', () {
      final clock = _FakeClock();
      final cubit = _cubit(_FakeRepository(null), clock: clock);

      clock.advance(const Duration(seconds: 30));
      expect(cubit.resendCooldownRemaining, 30);
      expect(cubit.canResend, isFalse);

      clock.advance(const Duration(seconds: 29));
      expect(cubit.resendCooldownRemaining, 1);
      expect(cubit.canResend, isFalse);

      clock.advance(const Duration(seconds: 1));
      expect(cubit.resendCooldownRemaining, 0);
      expect(cubit.canResend, isTrue);
    });

    test('never calls the repository while cooling down', () async {
      final repository = _FakeRepository(
        const EmailVerificationResult(message: 'resent'),
      );
      final cubit = _cubit(repository, clock: _FakeClock());

      await cubit.resend(email: email);

      expect(repository.resendCalls, isEmpty);
    });

    test('restarts the cooldown after a successful resend', () async {
      final clock = _FakeClock();
      final repository = _FakeRepository(
        const EmailVerificationResult(message: 'resent'),
      );
      final cubit = _cubit(repository, clock: clock);
      clock.advance(const Duration(seconds: 61));

      await cubit.resend(email: email);
      expect(cubit.resendCooldownRemaining, 60);
      expect(cubit.canResend, isFalse);

      clock.advance(const Duration(seconds: 60));
      expect(cubit.canResend, isTrue);
    });

    test('blocks resend while a confirm is in flight', () async {
      final clock = _FakeClock();
      final repository = _FakeRepository(
        const EmailVerificationResult(message: 'ok'),
      );
      final cubit = _cubit(repository, clock: clock);
      clock.advance(const Duration(seconds: 61));

      final confirming = cubit.confirm(email: email, otp: '482913');
      expect(cubit.canResend, isFalse);
      await cubit.resend(email: email);
      await confirming;

      expect(repository.resendCalls, isEmpty);
    });
  });

  group('EmailVerificationCubit.clearFailure', () {
    test('returns to initial and drops the failure', () async {
      final repository = _FakeRepository(
        null,
        failureException: const FailureException(
          Failure(FailureCode.validation, debugMessage: 'bad code'),
        ),
      );
      final cubit = _cubit(repository, clock: _FakeClock());

      await cubit.confirm(email: email, otp: '000000');
      expect(cubit.state.hasFailure, isTrue);

      cubit.clearFailure();

      expect(cubit.state.status, EmailVerificationStatus.initial);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.failedAction, isNull);
    });
  });

  test('cancels its cooldown timer on close', () async {
    final cubit = _cubit(_FakeRepository(null), clock: _FakeClock());

    await cubit.close();

    expect(cubit.isClosed, isTrue);
  });
}

EmailVerificationCubit _cubit(
  _FakeRepository repository, {
  required _FakeClock clock,
}) {
  return EmailVerificationCubit(
    confirmEmailUseCase: ConfirmEmailUseCase(repository),
    resendOtpUseCase: ResendOtpUseCase(repository),
    now: clock.now,
  );
}

class _FakeClock {
  DateTime _current = DateTime.utc(2026, 10, 6, 12);

  DateTime now() => _current;

  void advance(Duration by) => _current = _current.add(by);
}

class _Call {
  const _Call({required this.email, required this.otp});

  final String email;
  final String otp;
}

class _FakeRepository implements EmailVerificationRepository {
  _FakeRepository(this.result, {this.failureException, this.unexpectedError});

  final EmailVerificationResult? result;
  final FailureException? failureException;
  final Object? unexpectedError;
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
    // A real network call yields, which is what makes the "in flight" guards
    // observable in these tests.
    await Future<void>.delayed(Duration.zero);
    if (failureException != null) {
      throw failureException!;
    }
    if (unexpectedError != null) {
      throw unexpectedError!;
    }
    return result!;
  }
}
