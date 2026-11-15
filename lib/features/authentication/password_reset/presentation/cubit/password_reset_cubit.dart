import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../domain/usecases/forgot_password_use_case.dart';
import '../../domain/usecases/reset_password_use_case.dart';
import 'password_reset_state.dart';

/// Drives the whole password-reset flow from both screens.
///
/// It is registered as a **singleton** in the composition root, not a factory,
/// so the cooldown survives the Forgot → Reset navigation. The backend applies
/// no throttling of its own, so this client-side cooldown is the only
/// protection against repeated reset emails; recreating the cubit per page
/// would silently reset it.
class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit({
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    Duration requestCooldown = defaultRequestCooldown,
    DateTime Function()? now,
  })  : _forgotPasswordUseCase = forgotPasswordUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _requestCooldown = requestCooldown,
        _now = now ?? DateTime.now,
        super(const PasswordResetState.initial());

  /// The backend has no rate limiting, so this local window is the only thing
  /// preventing a flood of reset emails.
  static const Duration defaultRequestCooldown = Duration(seconds: 60);

  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final Duration _requestCooldown;
  final DateTime Function() _now;

  DateTime? _cooldownEndsAt;

  /// Whole seconds remaining before another reset code can be requested.
  /// Starts at zero, because — unlike email verification — no code has been
  /// sent yet when the user first reaches the Forgot screen.
  int get requestCooldownRemaining {
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

  bool get canRequest => requestCooldownRemaining == 0 && !state.isBusy;

  /// Sends the reset code. Also the mechanism behind the Reset screen's
  /// "resend", which is why [action] distinguishes the two callers.
  Future<void> requestReset({
    required String email,
    PasswordResetAction action = PasswordResetAction.request,
  }) async {
    // Blocked while anything is in flight and during the cooldown, which also
    // guarantees this can never fire automatically.
    if (state.isBusy || !canRequest) {
      return;
    }

    emit(
      state.copyWith(
        status: PasswordResetStatus.inFlight,
        pendingAction: action,
        clearFailure: true,
        clearMessage: true,
      ),
    );

    try {
      final result = await _forgotPasswordUseCase(email: email);
      if (!isClosed) {
        _cooldownEndsAt = _now().add(_requestCooldown);
        emit(
          state.copyWith(
            status: PasswordResetStatus.codeSent,
            message: result.message,
            lastAction: action,
            email: email.trim(),
            clearFailure: true,
            clearPending: true,
          ),
        );
      }
    } on FailureException catch (error) {
      if (!isClosed) {
        emit(_failureState(error.failure, action));
      }
    } catch (_) {
      if (!isClosed) {
        // Never surface the raw error text.
        emit(
          _failureState(
            const Failure(
              FailureCode.unknown,
              debugMessage: 'Reset code could not be requested',
            ),
            action,
          ),
        );
      }
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (state.isBusy) {
      return;
    }

    emit(
      state.copyWith(
        status: PasswordResetStatus.inFlight,
        pendingAction: PasswordResetAction.reset,
        clearFailure: true,
        clearMessage: true,
      ),
    );

    try {
      final result = await _resetPasswordUseCase(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PasswordResetStatus.resetDone,
            message: result.message,
            lastAction: PasswordResetAction.reset,
            clearFailure: true,
            clearPending: true,
          ),
        );
      }
    } on FailureException catch (error) {
      if (!isClosed) {
        emit(_failureState(error.failure, PasswordResetAction.reset));
      }
    } catch (_) {
      if (!isClosed) {
        // Never surface the raw error: it can contain the OTP or password.
        emit(
          _failureState(
            const Failure(
              FailureCode.unknown,
              debugMessage: 'Password could not be reset',
            ),
            PasswordResetAction.reset,
          ),
        );
      }
    }
  }

  /// Convenience wrapper for the Reset screen's resend button. There is no
  /// dedicated backend endpoint, so this deliberately re-requests the code.
  Future<void> resendCode({required String email}) {
    return requestReset(email: email, action: PasswordResetAction.resend);
  }

  /// Clears stale UI state when the Forgot screen is (re)entered, because the
  /// cubit outlives a single visit. The cooldown is intentionally **preserved**
  /// so re-entering the screen cannot be used to bypass it.
  void resetForNewRequest() {
    if (state.isBusy) {
      return;
    }
    emit(
      state.copyWith(
        status: PasswordResetStatus.idle,
        clearFailure: true,
        clearMessage: true,
        clearPending: true,
      ),
    );
  }

  /// Lets the user dismiss an inline error and try again.
  void clearFailure() {
    if (state.hasFailure) {
      emit(
        state.copyWith(
          status: PasswordResetStatus.idle,
          clearFailure: true,
          clearPending: true,
        ),
      );
    }
  }

  PasswordResetState _failureState(
      Failure failure, PasswordResetAction action) {
    return state.copyWith(
      status: PasswordResetStatus.failure,
      failure: failure,
      failedAction: action,
      clearMessage: true,
      clearPending: true,
    );
  }
}
