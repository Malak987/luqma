import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../../location/domain/entities/location_coordinates.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/entities/address_label.dart';
import '../../domain/usecases/create_address_use_case.dart';
import '../../domain/usecases/update_address_use_case.dart';
import 'address_form_state.dart';

/// Handles address details form validation and submission.
///
/// One cubit serves both flows: `POST /api/Address/Create` when no address is
/// passed in, and `PUT /api/Address/Update/{id}` when [initialAddress] is
/// supplied. In edit mode every field starts from the stored address, so the
/// user only changes what they mean to change — `label`, `isDefault` and the
/// coordinates survive untouched.
class AddressFormCubit extends Cubit<AddressFormState> {
  AddressFormCubit({
    required CreateAddressUseCase createAddressUseCase,
    required LocationCoordinates coordinates,
    UpdateAddressUseCase? updateAddressUseCase,
    Address? initialAddress,
  })  : _createAddressUseCase = createAddressUseCase,
        _updateAddressUseCase = updateAddressUseCase,
        super(_initialState(coordinates, initialAddress));

  final CreateAddressUseCase _createAddressUseCase;
  final UpdateAddressUseCase? _updateAddressUseCase;
  bool _isSubmitting = false;

  static AddressFormState _initialState(
    LocationCoordinates coordinates,
    Address? address,
  ) {
    if (address == null) {
      return AddressFormState(coordinates: coordinates);
    }
    return AddressFormState(
      coordinates: coordinates,
      title: address.title,
      district: address.district,
      city: address.city,
      details: address.details,
      label: address.label,
      isDefault: address.isDefault,
      addressId: address.id,
    );
  }

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

  void updateIsDefault(bool value) {
    if (isClosed) return;
    emit(state.copyWith(
      isDefault: value,
      status: AddressFormStatus.editing,
      clearFailure: true,
    ));
  }

  /// Applies a newly picked map position without dropping any typed text.
  void updateCoordinates(LocationCoordinates coordinates) {
    if (isClosed) return;
    emit(state.copyWith(
      coordinates: coordinates,
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

    final updateAddressUseCase = _updateAddressUseCase;
    final addressId = state.addressId;
    if (addressId != null && updateAddressUseCase == null) {
      // Editing without the update use case is a wiring mistake, not a user
      // error: report it instead of falling back to creating a duplicate.
      emit(state.copyWith(
        status: AddressFormStatus.failure,
        failure: const Failure(
          FailureCode.unknown,
          debugMessage: 'Update address use case is not configured',
        ),
      ));
      return;
    }

    _isSubmitting = true;
    emit(state.copyWith(
      status: AddressFormStatus.submitting,
      clearFailure: true,
      clearSavedAddress: true,
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
        isDefault: state.isDefault,
      );

      if (addressId != null) {
        final updated = await updateAddressUseCase!(id: addressId, address: draft);
        if (isClosed) return;
        emit(state.copyWith(
          status: AddressFormStatus.success,
          savedAddress: updated,
        ));
        return;
      }

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
