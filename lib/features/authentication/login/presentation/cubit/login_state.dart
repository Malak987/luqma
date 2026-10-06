import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  const LoginState({
    required this.status,
    this.failure,
  });

  const LoginState.initial() : this(status: LoginStatus.initial);

  final LoginStatus status;
  final Failure? failure;

  bool get isLoading => status == LoginStatus.loading;
  bool get isSuccess => status == LoginStatus.success;
  bool get hasFailure => status == LoginStatus.failure;

  LoginState copyWith({
    LoginStatus? status,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, failure];
}
