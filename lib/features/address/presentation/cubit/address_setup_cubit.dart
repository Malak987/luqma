import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_my_addresses_use_case.dart';
import 'address_setup_state.dart';

/// Controls the post-login address check gate.
/// Uses only the existing [GetMyAddressesUseCase] — no Dio/DataSource access.
class AddressSetupCubit extends Cubit<AddressSetupState> {
  AddressSetupCubit({required GetMyAddressesUseCase getMyAddressesUseCase})
      : _getMyAddressesUseCase = getMyAddressesUseCase,
        super(const AddressSetupState.initial());

  final GetMyAddressesUseCase _getMyAddressesUseCase;

  bool _isLoading = false;

  Future<void> load() async {
    if (isClosed) return;
    if (_isLoading || state.isLoading) {
      return;
    }
    _isLoading = true;
    if (isClosed) {
      _isLoading = false;
      return;
    }
    emit(const AddressSetupState(status: AddressSetupStatus.loading));
    try {
      final addresses = await _getMyAddressesUseCase();
      if (isClosed) return;
      if (addresses.isEmpty) {
        emit(const AddressSetupState(status: AddressSetupStatus.empty));
      } else {
        emit(AddressSetupState(
          status: AddressSetupStatus.populated,
          addresses: addresses,
        ));
      }
    } on FailureException catch (error) {
      if (isClosed) return;
      emit(AddressSetupState(
        status: AddressSetupStatus.error,
        failure: error.failure,
      ));
    } catch (error) {
      if (isClosed) return;
      emit(AddressSetupState(
        status: AddressSetupStatus.error,
        failure: Failure(
          FailureCode.unknown,
          debugMessage: error.toString(),
        ),
      ));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> retry() => load();

  // For tests only — not used in production.
  void emitForTest(AddressSetupState state) => emit(state);
  void emitErrorForTest() => emit(const AddressSetupState(
        status: AddressSetupStatus.error,
        failure: Failure(FailureCode.unknown),
      ));
  void emitEmptyForTest() =>
      emit(const AddressSetupState(status: AddressSetupStatus.empty));
}
