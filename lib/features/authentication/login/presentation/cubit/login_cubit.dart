import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../domain/usecases/login_use_case.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required LoginUseCase loginUseCase})
      : _loginUseCase = loginUseCase,
        super(const LoginState.initial());

  final LoginUseCase _loginUseCase;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (state.isLoading) {
      return;
    }

    emit(const LoginState(status: LoginStatus.loading));
    try {
      await _loginUseCase(
        email: email,
        password: password,
      );
      if (!isClosed) {
        emit(const LoginState(status: LoginStatus.success));
      }
    } on FailureException catch (error) {
      if (!isClosed) {
        emit(LoginState(status: LoginStatus.failure, failure: error.failure));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          LoginState(
            status: LoginStatus.failure,
            failure: Failure(
              FailureCode.unknown,
              debugMessage: error.toString(),
            ),
          ),
        );
      }
    }
  }

  void reset() {
    emit(const LoginState.initial());
  }
}
