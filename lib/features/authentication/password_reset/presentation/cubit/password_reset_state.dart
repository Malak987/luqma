import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';

enum PasswordResetStatus {
  /// Idle, or a form is waiting for the user.
  idle,

  /// A `ForgotPassword` call is in flight. Which button spins is decided by
  /// [PasswordResetState.pendingAction], because the same endpoint backs both
  /// the initial request and the Reset screen's resend.
  inFlight,

  /// A reset code is on its way; the user should now be on the Reset screen.
  codeSent,

  /// The password was changed successfully.
  resetDone,

  failure,
}

enum PasswordResetAction { request, resend, reset }

class PasswordResetState extends Equatable {
  const PasswordResetState({
    required this.status,
    this.pendingAction,
    this.failure,
    this.failedAction,
    this.message,
    this.lastAction,
    this.email,
  });

  const PasswordResetState.initial() : this(status: PasswordResetStatus.idle);

  final PasswordResetStatus status;

  /// The operation currently in flight. Needed because `request` and `resend`
  /// hit the same endpoint but belong to different buttons on different pages.
  final PasswordResetAction? pendingAction;

  final Failure? failure;
  final PasswordResetAction? failedAction;

  /// The backend's text from the most recent successful call.
  final String? message;

  final PasswordResetAction? lastAction;

  /// The address a reset code was successfully sent to. The Reset screen uses
  /// it for resending when it was not handed the email via route arguments.
  final String? email;

  bool get isBusy => status == PasswordResetStatus.inFlight;
  bool get isRequesting => isBusy && pendingAction == PasswordResetAction.request;
  bool get isResending => isBusy && pendingAction == PasswordResetAction.resend;
  bool get isResetting => isBusy && pendingAction == PasswordResetAction.reset;
  bool get isCodeSent => status == PasswordResetStatus.codeSent;
  bool get isResetDone => status == PasswordResetStatus.resetDone;
  bool get hasFailure => status == PasswordResetStatus.failure;

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    PasswordResetAction? pendingAction,
    Failure? failure,
    PasswordResetAction? failedAction,
    String? message,
    PasswordResetAction? lastAction,
    String? email,
    bool clearFailure = false,
    bool clearMessage = false,
    bool clearPending = false,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      pendingAction:
          clearPending ? null : pendingAction ?? this.pendingAction,
      failure: clearFailure ? null : failure ?? this.failure,
      failedAction: clearFailure ? null : failedAction ?? this.failedAction,
      message: clearMessage ? null : message ?? this.message,
      lastAction: lastAction ?? this.lastAction,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        pendingAction,
        failure,
        failedAction,
        message,
        lastAction,
        email,
      ];
}
