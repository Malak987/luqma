import 'package:equatable/equatable.dart';

enum FailureCode {
  validation,
  invalidCredentials,
  network,
  unknown,
}

class Failure extends Equatable {
  const Failure(this.code, {this.debugMessage});

  final FailureCode code;
  final String? debugMessage;

  @override
  List<Object?> get props => <Object?>[code, debugMessage];
}

class FailureException implements Exception {
  const FailureException(this.failure);

  final Failure failure;
}

class RemoteException implements Exception {
  const RemoteException({required this.code, this.message});

  final FailureCode code;
  final String? message;
}
