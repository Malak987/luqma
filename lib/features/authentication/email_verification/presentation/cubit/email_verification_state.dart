import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';

enum EmailVerificationStatus { initial, confirming, confirmed, failure }

/// Identifies which of the two operations a state change came from, so the UI
/// can show a failure in the right place and spin only the right button.
enum EmailVerificationAction { confirm, resend }

class EmailVerificationState extends Equatable {
  const EmailVerificationState({
    required this.status,
    this.isResending = false,
    this.failure,
    this.failedAction,
    this.message,
    this.lastAction,
  });

  const EmailVerificationState.initial()
      : this(status: EmailVerificationStatus.initial);

  final EmailVerificationStatus status;

  /// Tracked separately from [status] so a resend can run while the confirm
  /// form stays usable, and so the two buttons never share one spinner.
  final bool isResending;

  final Failure? failure;
  final EmailVerificationAction? failedAction;

  /// The backend's confirmation text, present after a successful operation.
  final String? message;

  final EmailVerificationAction? lastAction;

  bool get isConfirming => status == EmailVerificationStatus.confirming;
  bool get isConfirmed => status == EmailVerificationStatus.confirmed;
  bool get hasFailure => status == EmailVerificationStatus.failure;

  /// True while either operation is in flight. Used to block duplicate
  /// submissions of both kinds.
  bool get isBusy => isConfirming || isResending;

  EmailVerificationState copyWith({
    EmailVerificationStatus? status,
    bool? isResending,
    Failure? failure,
    EmailVerificationAction? failedAction,
    String? message,
    EmailVerificationAction? lastAction,
    bool clearFailure = false,
    bool clearMessage = false,
  }) {
    return EmailVerificationState(
      status: status ?? this.status,
      isResending: isResending ?? this.isResending,
      failure: clearFailure ? null : failure ?? this.failure,
      failedAction: clearFailure ? null : failedAction ?? this.failedAction,
      message: clearMessage ? null : message ?? this.message,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        isResending,
        failure,
        failedAction,
        message,
        lastAction,
      ];
}
