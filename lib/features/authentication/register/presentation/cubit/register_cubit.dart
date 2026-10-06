import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../domain/usecases/register_use_case.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({required RegisterUseCase registerUseCase})
      : _registerUseCase = registerUseCase,
        super(const RegisterState.initial());

  final RegisterUseCase _registerUseCase;

  Future<void> register({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String address,
  }) async {
    // Ignore repeat submissions while a request is already in flight.
    if (state.isLoading) {
      return;
    }

    emit(const RegisterState(status: RegisterStatus.loading));
    try {
      final result = await _registerUseCase(
        userName: userName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber,
        address: address,
      );
      if (!isClosed) {
        emit(
          RegisterState(
            status: RegisterStatus.success,
            message: result.message,
          ),
        );
      }
    } on FailureException catch (error) {
      if (!isClosed) {
        emit(
          RegisterState(
            status: RegisterStatus.failure,
            failure: error.failure,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          const RegisterState(
            status: RegisterStatus.failure,
            failure: Failure(
              FailureCode.unknown,
              debugMessage: 'Register could not be completed',
            ),
          ),
        );
      }
    }
  }

  void reset() {
    emit(const RegisterState.initial());
  }
}
