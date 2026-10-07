import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../domain/usecases/confirm_email_use_case.dart';
import '../../domain/usecases/resend_otp_use_case.dart';
import 'email_verification_state.dart';

class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  EmailVerificationCubit({
    required ConfirmEmailUseCase confirmEmailUseCase,
    required ResendOtpUseCase resendOtpUseCase,
    Duration resendCooldown = defaultResendCooldown,
    DateTime Function()? now,
  })  : _confirmEmailUseCase = confirmEmailUseCase,
        _resendOtpUseCase = resendOtpUseCase,
        _resendCooldown = resendCooldown,
        _now = now ?? DateTime.now,
        super(const EmailVerificationState.initial()) {
    // Register already sent the first OTP, so the cooldown starts on entry to
    // the screen rather than after the user's first tap. This also means the
    // screen never triggers a resend by itself.
    _cooldownEndsAt = _now().add(_resendCooldown);
    _startCooldownTimer();
  }

  /// Matches the 60-second local cooldown required by the product rules. The
  /// backend has no throttling of its own, so this is the only protection.
  static const Duration defaultResendCooldown = Duration(seconds: 60);

  final ConfirmEmailUseCase _confirmEmailUseCase;
  final ResendOtpUseCase _resendOtpUseCase;
  final Duration _resendCooldown;
  final DateTime Function() _now;

  Timer? _cooldownTimer;
  DateTime? _cooldownEndsAt;

  /// Whole seconds remaining before another resend is allowed.
  int get resendCooldownRemaining {
    final endsAt = _cooldownEndsAt;
    if (endsAt == null) {
      return 0;
    }
    final remaining = endsAt.difference(_now()).inMilliseconds;
    if (remaining <= 0) {
      return 0;
    }
    return (remaining / 1000).ceil();
  }

  bool get canResend => resendCooldownRemaining == 0 && !state.isBusy;

  Future<void> confirm({
    required String email,
    required String otp,
  }) async {
    // Ignore repeat submissions while anything is already in flight.
    if (state.isBusy) {
      return;
    }

    emit(
      state.copyWith(
        status: EmailVerificationStatus.confirming,
        clearFailure: true,
        clearMessage: true,
      ),
    );

    try {
      final result = await _confirmEmailUseCase(email: email, otp: otp);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: EmailVerificationStatus.confirmed,
            message: result.message,
            lastAction: EmailVerificationAction.confirm,
            clearFailure: true,
          ),
        );
      }
    } on FailureException catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: EmailVerificationStatus.failure,
            failure: error.failure,
            failedAction: EmailVerificationAction.confirm,
            clearMessage: true,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        // Never surface the raw error: it can contain the OTP.
        emit(
          state.copyWith(
            status: EmailVerificationStatus.failure,
            failure: const Failure(
              FailureCode.unknown,
              debugMessage: 'Email verification could not be completed',
            ),
            failedAction: EmailVerificationAction.confirm,
            clearMessage: true,
          ),
        );
      }
    }
  }

  Future<void> resend({required String email}) async {
    // Blocked while a request is in flight and during the local cooldown,
    // which also guarantees this is never fired automatically.
    if (state.isBusy || !canResend) {
      return;
    }

    emit(state.copyWith(isResending: true, clearFailure: true));

    try {
      final result = await _resendOtpUseCase(email: email);
      if (!isClosed) {
        _cooldownEndsAt = _now().add(_resendCooldown);
        _startCooldownTimer();
        emit(
          state.copyWith(
            isResending: false,
            message: result.message,
            lastAction: EmailVerificationAction.resend,
            clearFailure: true,
          ),
        );
      }
    } on FailureException catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isResending: false,
            failure: error.failure,
            failedAction: EmailVerificationAction.resend,
            clearMessage: true,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isResending: false,
            failure: const Failure(
              FailureCode.unknown,
              debugMessage: 'Resend could not be completed',
            ),
            failedAction: EmailVerificationAction.resend,
            clearMessage: true,
          ),
        );
      }
    }
  }

  /// Lets the user dismiss an inline error and try again.
  void clearFailure() {
    if (state.hasFailure) {
      emit(
        state.copyWith(
          status: EmailVerificationStatus.initial,
          clearFailure: true,
        ),
      );
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) {
        _cooldownTimer?.cancel();
        return;
      }
      if (resendCooldownRemaining == 0) {
        _cooldownTimer?.cancel();
      }
      // The page rebuilds from its own ticker for the visible countdown; this
      // timer only guarantees the cubit stops work once the window closes.
    });
  }

  @override
  Future<void> close() {
    _cooldownTimer?.cancel();
    return super.close();
  }
}
