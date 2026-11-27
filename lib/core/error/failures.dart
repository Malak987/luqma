import 'package:equatable/equatable.dart';

enum FailureCode {
  validation,
  invalidCredentials,
  network,
  unknown,
}

class Failure extends Equatable {
  const Failure(this.code, {this.debugMessage, this.backendCode});

  final FailureCode code;
  final String? debugMessage;
  final String? backendCode;

  @override
  List<Object?> get props => <Object?>[code, debugMessage, backendCode];
}

class FailureException implements Exception {
  const FailureException(this.failure);

  final Failure failure;
}

class RemoteException implements Exception {
  const RemoteException({required this.code, this.message, this.backendCode});

  final FailureCode code;
  final String? message;
  final String? backendCode;
}
