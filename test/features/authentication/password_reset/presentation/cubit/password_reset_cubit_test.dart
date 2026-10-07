import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/entities/password_reset_result.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/repositories/password_reset_repository.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/usecases/forgot_password_use_case.dart';
import 'package:luqma_app/features/authentication/password_reset/domain/usecases/reset_password_use_case.dart';
import 'package:luqma_app/features/authentication/password_reset/presentation/cubit/password_reset_cubit.dart';
import 'package:luqma_app/features/authentication/password_reset/presentation/cubit/password_reset_state.dart';

import '../../fake_clock.dart';

const _email = 'person@example.test';

void main() {
  group('PasswordResetCubit.requestReset', () {
    test('starts with no cooldown, because no code has been sent yet', () {
      final cubit = _cubit(_FakeRepository());

      expect(cubit.state.status, PasswordResetStatus.idle);
      expect(cubit.requestCooldownRemaining, 0);
      expect(cubit.canRequest, isTrue);
    });

    test('emits inFlight then codeSent with the backend message', () async {
      final repository = _FakeRepository(
        forgotResult: const PasswordResetResult(
          message: 'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        ),
      );
      final cubit = _cubit(repository);

      final emissions = await _emissionsDuring(
        cubit,
        () => cubit.requestReset(email: _email),
      );

      expect(emissions, hasLength(2));
      expect(emissions[0].status, PasswordResetStatus.inFlight);
      expect(emissions[0].pendingAction, PasswordResetAction.request);
      expect(emissions[0].isRequesting, isTrue);
      expect(emissions[1].status, PasswordResetStatus.codeSent);
      expect(
        emissions[1].message,
        'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      );
      expect(emissions[1].email, _email);
      expect(emissions[1].lastAction, PasswordResetAction.request);
      expect(emissions[1].isCodeSent, isTrue);
      expect(emissions[1].pendingAction, isNull);
    });

    test('starts a 60-second cooldown after a successful request', () async {
      final clock = FakeClock();
      final cubit = _cubit(
        _FakeRepository(forgotResult: const PasswordResetResult(message: 'ok')),
        clock: clock,
      );

      await cubit.requestReset(email: _email);
      expect(cubit.requestCooldownRemaining, 60);
      expect(cubit.canRequest, isFalse,
          reason: 'the backend applies no throttling, so the client must');

      clock.advance(const Duration(seconds: 59));
      expect(cubit.requestCooldownRemaining, 1);
      expect(cubit.canRequest, isFalse);

      clock.advance(const Duration(seconds: 1));
      expect(cubit.requestCooldownRemaining, 0);
      expect(cubit.canRequest, isTrue);
    });

    test('does not start the cooldown when the request fails', () async {
      final clock = FakeClock();
      final cubit = _cubit(
        _FakeRepository(
          forgotError: const FailureException(Failure(
            FailureCode.validation,
            debugMessage: 'البريد الإلكتروني غير موجود',
          )),
        ),
        clock: clock,
      );

      await cubit.requestReset(email: _email);

      expect(cubit.requestCooldownRemaining, 0,
          reason: 'a rejected request sent no email, so there is nothing to '
              'wait for');
      expect(cubit.canRequest, isTrue);
    });

    test('emits failure and keeps the backend message when the email is '
        'unknown', () async {
      final cubit = _cubit(
        _FakeRepository(
          forgotError: const FailureException(Failure(
            FailureCode.validation,
            debugMessage: 'البريد الإلكتروني غير موجود',
          )),
        ),
      );

      final emissions = await _emissionsDuring(
        cubit,
        () => cubit.requestReset(email: _email),
      );

      expect(emissions, hasLength(2));
      expect(emissions[0].status, PasswordResetStatus.inFlight);
      expect(emissions[1].status, PasswordResetStatus.failure);
      expect(emissions[1].failedAction, PasswordResetAction.request);
      expect(
        emissions[1].failure?.debugMessage,
        'البريد الإلكتروني غير موجود',
      );
      expect(emissions[1].failure?.code, FailureCode.validation);
      expect(emissions[1].message, isNull,
          reason: 'a failure must not keep the previous success text');
    });

    test('ignores a request while one is already in flight', () async {
      final repository = _FakeRepository(
        forgotResult: const PasswordResetResult(message: 'ok'),
      );
      final cubit = _cubit(repository);

      final first = cubit.requestReset(email: _email);
      await cubit.requestReset(email: _email);
      await cubit.requestReset(email: _email);
      await first;

      expect(repository.forgotCalls, 1,
          reason: 'a double tap must not send a second email');
    });

    test('ignores a request during the cooldown', () async {
      final clock = FakeClock();
      final repository = _FakeRepository(
        forgotResult: const PasswordResetResult(message: 'ok'),
      );
      final cubit = _cubit(repository, clock: clock);

      await cubit.requestReset(email: _email);
      clock.advance(const Duration(seconds: 30));
      await cubit.requestReset(email: _email);
      await cubit.resendCode(email: _email);

      expect(repository.forgotCalls, 1);

      clock.advance(const Duration(seconds: 31));
      await cubit.requestReset(email: _email);
      expect(repository.forgotCalls, 2,
          reason: 'once the window passes, requesting again is allowed');
    });

    test('stores the trimmed email in the state', () async {
      final repository = _FakeRepository(
        forgotResult: const PasswordResetResult(message: 'ok'),
      );
      final cubit = _cubit(repository);

      await cubit.requestReset(email: '  $_email  ');

      expect(cubit.state.email, _email);
    });

    test('converts an unexpected error into an unknown failure without '
        'echoing the raw error', () async {
      final cubit = _cubit(
        _FakeRepository(forgotError: StateError('boom with a secret')),
      );

      final emissions = await _emissionsDuring(
        cubit,
        () => cubit.requestReset(email: _email),
      );

      expect(emissions, hasLength(2));
      expect(emissions[1].failure?.code, FailureCode.unknown);
      expect(emissions[1].failure?.debugMessage, isNot(contains('secret')));
    });
  });

  group('PasswordResetCubit.resendCode', () {
    test('calls ForgotPassword again, because no dedicated resend endpoint '
        'exists', () async {
      final repository = _FakeRepository(
        forgotResult: const PasswordResetResult(message: 'أُرسل الرمز'),
      );
      final clock = FakeClock();
      final cubit = _cubit(repository, clock: clock);

      await cubit.requestReset(email: _email);
      clock.advance(const Duration(seconds: 61));
      await cubit.resendCode(email: _email);

      expect(repository.forgotCalls, 2);
      expect(repository.forgotEmail, _email);
      expect(repository.resetCalls, 0,
          reason: 'resending a code must not reset the password');
    });

    test('marks the resend distinctly from the first request', () async {
      final clock = FakeClock();
      final cubit = _cubit(
        _FakeRepository(forgotResult: const PasswordResetResult(message: 'ok')),
        clock: clock,
      );

      await cubit.requestReset(email: _email);
      clock.advance(const Duration(seconds: 61));

      final emissions = await _emissionsDuring(
        cubit,
        () => cubit.resendCode(email: _email),
      );

      expect(emissions, hasLength(2));
      expect(emissions[0].status, PasswordResetStatus.inFlight);
      expect(emissions[0].pendingAction, PasswordResetAction.resend);
      expect(emissions[0].isResending, isTrue);
      expect(emissions[0].isRequesting, isFalse);
      expect(emissions[1].lastAction, PasswordResetAction.resend);
    });

    test('reuses the 60-second cooldown window', () async {
      final clock = FakeClock();
      final cubit = _cubit(
        _FakeRepository(forgotResult: const PasswordResetResult(message: 'ok')),
        clock: clock,
      );

      await cubit.requestReset(email: _email);
      clock.advance(const Duration(seconds: 61));
      await cubit.resendCode(email: _email);

      expect(cubit.requestCooldownRemaining, 60);
      expect(cubit.canRequest, isFalse);
    });

    test('emits failure with the resend action when it fails', () async {
      final clock = FakeClock();
      final repository = _FakeRepository(
        forgotResult: const PasswordResetResult(message: 'ok'),
      );
      final cubit = _cubit(repository, clock: clock);

      await cubit.requestReset(email: _email);
      clock.advance(const Duration(seconds: 61));
      repository.forgotError = const FailureException(
        Failure(FailureCode.network),
      );

      final emissions = await _emissionsDuring(
        cubit,
        () => cubit.resendCode(email: _email),
      );

      expect(emissions, hasLength(2));
      expect(emissions[0].status, PasswordResetStatus.inFlight);
      expect(emissions[1].failedAction, PasswordResetAction.resend);
      expect(emissions[1].failure?.code, FailureCode.network);
    });
  });

  group('PasswordResetCubit.resetPassword', () {
    test('emits inFlight then resetDone with the backend message', () async {
      final cubit = _cubit(
        _FakeRepository(
          resetResult: const PasswordResetResult(message: 'تم التعديل بنجاح'),
        ),
      );

      final emissions = await _emissionsDuring(
        cubit,
        () => cubit.resetPassword(
          email: _email,
          otp: '482913',
          newPassword: 'NewPassw0rd!',
        ),
      );

      expect(emissions, hasLength(2));
      expect(emissions[0].status, PasswordResetStatus.inFlight);
      expect(emissions[0].pendingAction, PasswordResetAction.reset);
      expect(emissions[0].isResetting, isTrue);
      expect(emissions[1].status, PasswordResetStatus.resetDone);
      expect(emissions[1].message, 'تم التعديل بنجاح');
      expect(emissions[1].isResetDone, isTrue);
    });

    test('passes all three fields through untouched', () async {
      final repository = _FakeRepository(
        resetResult: const PasswordResetResult(message: 'ok'),
      );

      await _cubit(repository).resetPassword(
        email: ' $_email ',
        otp: ' 482913 ',
        newPassword: 'NewPassw0rd!',
      );

      expect(repository.resetEmail, ' $_email ',
          reason: 'the cubit forwards as typed; the repository trims');
      expect(repository.resetOtp, ' 482913 ');
      expect(repository.resetNewPassword, 'NewPassw0rd!',
          reason: 'the password must never be trimmed');
      expect(repository.forgotCalls, 0);
    });

    test('does not touch the request cooldown', () async {
      final clock = FakeClock();
      final cubit = _cubit(
        _FakeRepository(
          forgotResult: const PasswordResetResult(message: 'ok'),
          resetResult: const PasswordResetResult(message: 'done'),
        ),
        clock: clock,
      );

      await cubit.requestReset(email: _email);
      clock.advance(const Duration(seconds: 20));
      await cubit.resetPassword(
        email: _email,
        otp: '482913',
        newPassword: 'NewPassw0rd!',
      );

      expect(cubit.requestCooldownRemaining, 40);
    });

    test('emits failure and keeps the invalid-OTP message', () async {
      final cubit = _cubit(
        _FakeRepository(
          resetError: const FailureException(Failure(
            FailureCode.validation,
            debugMessage: 'رمز التحقق غير صحيح أو منتهي الصلاحية',
          )),
        ),
      );

      final emissions = await _emissionsDuring(
        cubit,
        () => cubit.resetPassword(
          email: _email,
          otp: '000000',
          newPassword: 'NewPassw0rd!',
        ),
      );

      expect(emissions, hasLength(2));
      expect(emissions[0].status, PasswordResetStatus.inFlight);
      expect(emissions[1].status, PasswordResetStatus.failure);
      expect(emissions[1].failedAction, PasswordResetAction.reset);
      expect(
        emissions[1].failure?.debugMessage,
        'رمز التحقق غير صحيح أو منتهي الصلاحية',
      );
    });

    test('ignores a second reset while one is in flight', () async {
      final repository = _FakeRepository(
        resetResult: const PasswordResetResult(message: 'ok'),
      );
      final cubit = _cubit(repository);

      final first = cubit.resetPassword(
        email: _email,
        otp: '482913',
        newPassword: 'NewPassw0rd!',
      );
      await cubit.resetPassword(
        email: _email,
        otp: '482913',
        newPassword: 'NewPassw0rd!',
      );
      await first;

      expect(repository.resetCalls, 1);
    });
  });

  group('PasswordResetCubit.resetForNewRequest', () {
    test('clears a stale failure but keeps the running cooldown', () async {
      final clock = FakeClock();
      final cubit = _cubit(
        _FakeRepository(
          forgotResult: const PasswordResetResult(message: 'ok'),
          resetError: const FailureException(Failure(
            FailureCode.validation,
            debugMessage: 'رمز التحقق غير صحيح أو منتهي الصلاحية',
          )),
        ),
        clock: clock,
      );

      await cubit.requestReset(email: _email);
      await cubit.resetPassword(
        email: _email,
        otp: '000000',
        newPassword: 'NewPassw0rd!',
      );
      expect(cubit.state.hasFailure, isTrue);

      cubit.resetForNewRequest();

      expect(cubit.state.status, PasswordResetStatus.idle);
      expect(cubit.state.hasFailure, isFalse);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.message, isNull);
      expect(cubit.requestCooldownRemaining, 60,
          reason: 'the spam window must survive leaving and re-entering');
      expect(cubit.state.email, _email,
          reason: 'the address is reused on the next screen');
    });

    test('is ignored while a call is in flight', () async {
      final repository = _FakeRepository(
        forgotResult: const PasswordResetResult(message: 'ok'),
      );
      final cubit = _cubit(repository);
      final pending = cubit.requestReset(email: _email);

      cubit.resetForNewRequest();
      await pending;

      expect(cubit.state.status, PasswordResetStatus.codeSent);
    });
  });

  group('PasswordResetCubit.clearFailure', () {
    test('clears the failure but keeps the cooldown', () async {
      final clock = FakeClock();
      final cubit = _cubit(
        _FakeRepository(
          forgotResult: const PasswordResetResult(message: 'تم الإرسال'),
          resetError: const FailureException(
            Failure(FailureCode.validation, debugMessage: 'رمز خاطئ'),
          ),
        ),
        clock: clock,
      );

      await cubit.requestReset(email: _email);
      await cubit.resetPassword(
        email: _email,
        otp: '000000',
        newPassword: 'NewPassw0rd!',
      );
      expect(cubit.state.hasFailure, isTrue);

      cubit.clearFailure();

      expect(cubit.state.hasFailure, isFalse);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.failedAction, isNull);
      expect(cubit.state.status, PasswordResetStatus.idle);
      expect(cubit.requestCooldownRemaining, 60);
    });

    test('does nothing when there is no failure to clear', () async {
      final cubit = _cubit(
        _FakeRepository(forgotResult: const PasswordResetResult(message: 'ok')),
      );

      await cubit.requestReset(email: _email);
      final before = cubit.state;
      cubit.clearFailure();

      expect(cubit.state, before);
      expect(cubit.state.status, PasswordResetStatus.codeSent);
    });
  });

  group('PasswordResetState', () {
    test('derives the three loading flags from one in-flight status', () {
      const requesting = PasswordResetState(
        status: PasswordResetStatus.inFlight,
        pendingAction: PasswordResetAction.request,
      );
      expect(requesting.isRequesting, isTrue);
      expect(requesting.isResending, isFalse);
      expect(requesting.isResetting, isFalse);
      expect(requesting.isBusy, isTrue);

      const resending = PasswordResetState(
        status: PasswordResetStatus.inFlight,
        pendingAction: PasswordResetAction.resend,
      );
      expect(resending.isResending, isTrue);
      expect(resending.isRequesting, isFalse);
      expect(resending.isResetting, isFalse);

      const resetting = PasswordResetState(
        status: PasswordResetStatus.inFlight,
        pendingAction: PasswordResetAction.reset,
      );
      expect(resetting.isResetting, isTrue);
      expect(resetting.isRequesting, isFalse);
      expect(resetting.isBusy, isTrue);
    });

    test('reports no loading flag while idle', () {
      const idle = PasswordResetState.initial();
      expect(idle.status, PasswordResetStatus.idle);
      expect(idle.isBusy, isFalse);
      expect(idle.isRequesting, isFalse);
      expect(idle.isResending, isFalse);
      expect(idle.isResetting, isFalse);
      expect(idle.isCodeSent, isFalse);
      expect(idle.isResetDone, isFalse);
      expect(idle.hasFailure, isFalse);
    });

    test('treats a failure status as the failure flag', () {
      const failed = PasswordResetState(
        status: PasswordResetStatus.failure,
        failure: Failure(FailureCode.network),
        failedAction: PasswordResetAction.reset,
      );
      expect(failed.hasFailure, isTrue);
      expect(failed.isBusy, isFalse);
    });

    test('has value equality', () {
      const a = PasswordResetState(
        status: PasswordResetStatus.codeSent,
        message: 'ok',
        email: _email,
      );
      const b = PasswordResetState(
        status: PasswordResetStatus.codeSent,
        message: 'ok',
        email: _email,
      );
      const c = PasswordResetState(
        status: PasswordResetStatus.codeSent,
        message: 'different',
        email: _email,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('clears only what the flags ask for', () {
      const base = PasswordResetState(
        status: PasswordResetStatus.failure,
        pendingAction: PasswordResetAction.reset,
        message: 'stale',
        failure: Failure(FailureCode.network),
        failedAction: PasswordResetAction.reset,
        lastAction: PasswordResetAction.request,
        email: _email,
      );

      final cleared = base.copyWith(
        status: PasswordResetStatus.idle,
        clearFailure: true,
        clearMessage: true,
        clearPending: true,
      );

      expect(cleared.status, PasswordResetStatus.idle);
      expect(cleared.message, isNull);
      expect(cleared.failure, isNull);
      expect(cleared.failedAction, isNull);
      expect(cleared.pendingAction, isNull);
      expect(cleared.email, _email, reason: 'the address must survive');
      expect(cleared.lastAction, PasswordResetAction.request);
    });

    test('keeps untouched fields when copying', () {
      const base = PasswordResetState(
        status: PasswordResetStatus.codeSent,
        message: 'ok',
        email: _email,
        lastAction: PasswordResetAction.request,
      );

      final copy = base.copyWith(status: PasswordResetStatus.inFlight);

      expect(copy.status, PasswordResetStatus.inFlight);
      expect(copy.message, 'ok');
      expect(copy.email, _email);
      expect(copy.lastAction, PasswordResetAction.request);
    });
  });
}

/// Runs [action] and returns every state the cubit emitted while it ran.
///
/// `emitsInOrder` would wait for the stream to close, which only happens when
/// the cubit is closed, so the emissions are collected directly instead. The
/// extra yield matters: a cubit delivers its **last** emission to listeners a
/// microtask after the returned future completes, so cancelling the
/// subscription straight after `await action()` would drop it.
Future<List<PasswordResetState>> _emissionsDuring(
  PasswordResetCubit cubit,
  Future<void> Function() action,
) async {
  final emissions = <PasswordResetState>[];
  final subscription = cubit.stream.listen(emissions.add);
  await action();
  await Future<void>.delayed(Duration.zero);
  await subscription.cancel();
  return emissions;
}

PasswordResetCubit _cubit(
  _FakeRepository repository, {
  FakeClock? clock,
}) {
  return PasswordResetCubit(
    forgotPasswordUseCase: ForgotPasswordUseCase(repository),
    resetPasswordUseCase: ResetPasswordUseCase(repository),
    now: (clock ?? FakeClock()).now,
  );
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
  Object? forgotError;
  Object? resetError;

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
    // Yield so a caller that fires twice without awaiting hits the busy guard.
    await Future<void>.delayed(Duration.zero);
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
    await Future<void>.delayed(Duration.zero);
    final error = resetError;
    if (error != null) {
      throw error;
    }
    return resetResult!;
  }
}
