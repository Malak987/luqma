import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../../location/domain/entities/location_coordinates.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/entities/address_label.dart';
import '../../domain/usecases/create_address_use_case.dart';
import 'address_form_state.dart';

/// Handles address details form validation and submission.
/// Preserves the selected [LocationCoordinates] throughout the flow and never
/// replaces it with a fallback. Uses the verified `POST /api/Address/Create`
/// payload via [CreateAddressUseCase].
class AddressFormCubit extends Cubit<AddressFormState> {
  AddressFormCubit({
    required CreateAddressUseCase createAddressUseCase,
    required LocationCoordinates coordinates,
  })  : _createAddressUseCase = createAddressUseCase,
        super(AddressFormState(coordinates: coordinates));

  final CreateAddressUseCase _createAddressUseCase;
  bool _isSubmitting = false;

  void updateTitle(String value) {
    if (isClosed) return;
    emit(state.copyWith(
      title: value,
      status: AddressFormStatus.editing,
      clearTitleError: true,
      clearFailure: true,
    ));
  }

  void updateDistrict(String value) {
    if (isClosed) return;
    emit(state.copyWith(
      district: value,
      status: AddressFormStatus.editing,
      clearDistrictError: true,
      clearFailure: true,
    ));
  }

  void updateCity(String value) {
    if (isClosed) return;
    emit(state.copyWith(
      city: value,
      status: AddressFormStatus.editing,
      clearCityError: true,
      clearFailure: true,
    ));
  }

  void updateDetails(String value) {
    if (isClosed) return;
    emit(state.copyWith(
      details: value,
      status: AddressFormStatus.editing,
      clearDetailsError: true,
      clearFailure: true,
    ));
  }

  void updateLabel(AddressLabel label) {
    if (isClosed) return;
    emit(state.copyWith(
      label: label,
      status: AddressFormStatus.editing,
      clearFailure: true,
    ));
  }

  bool _validate() {
    final titleError = Validators.requiredText(state.title);
    final districtError = Validators.requiredText(state.district);
    final cityError = Validators.requiredText(state.city);
    final detailsError = Validators.requiredText(state.details);

    if (titleError != null ||
        districtError != null ||
        cityError != null ||
        detailsError != null) {
      emit(state.copyWith(
        status: AddressFormStatus.editing,
        titleError: titleError,
        districtError: districtError,
        cityError: cityError,
        detailsError: detailsError,
        clearTitleError: titleError == null,
        clearDistrictError: districtError == null,
        clearCityError: cityError == null,
        clearDetailsError: detailsError == null,
      ));
      return false;
    }
    // Clear previous validation errors on success
    emit(state.copyWith(
      status: AddressFormStatus.editing,
      clearTitleError: true,
      clearDistrictError: true,
      clearCityError: true,
      clearDetailsError: true,
    ));
    return true;
  }

  Future<void> submit() async {
    if (isClosed) return;
    if (_isSubmitting || state.isSubmitting) return;
    if (!_validate()) return;

    _isSubmitting = true;
    emit(state.copyWith(
      status: AddressFormStatus.submitting,
      clearFailure: true,
    ));

    try {
      final draft = AddressDraft(
        label: state.label,
        title: state.title.trim(),
        district: state.district.trim(),
        city: state.city.trim(),
        details: state.details.trim(),
        latitude: state.coordinates.latitude,
        longitude: state.coordinates.longitude,
        // First address should be default; API supports isDefault.
        isDefault: state.isDefault,
      );

      await _createAddressUseCase(address: draft);
      if (isClosed) return;
      emit(state.copyWith(status: AddressFormStatus.success));
    } on FailureException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: AddressFormStatus.failure,
        failure: e.failure,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: AddressFormStatus.failure,
        failure: Failure(FailureCode.unknown, debugMessage: e.toString()),
      ));
    } finally {
      _isSubmitting = false;
    }
  }

  void retrySubmit() => submit();
}
