import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';

enum RegisterStatus { initial, loading, success, failure }

class RegisterState extends Equatable {
  const RegisterState({
    required this.status,
    this.failure,
    this.message,
  });

  const RegisterState.initial() : this(status: RegisterStatus.initial);

  final RegisterStatus status;
  final Failure? failure;

  /// The backend's confirmation text, present only on success.
  final String? message;

  bool get isLoading => status == RegisterStatus.loading;
  bool get isSuccess => status == RegisterStatus.success;
  bool get hasFailure => status == RegisterStatus.failure;

  RegisterState copyWith({
    RegisterStatus? status,
    Failure? failure,
    String? message,
    bool clearFailure = false,
    bool clearMessage = false,
  }) {
    return RegisterState(
      status: status ?? this.status,
      failure: clearFailure ? null : failure ?? this.failure,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, failure, message];
}
