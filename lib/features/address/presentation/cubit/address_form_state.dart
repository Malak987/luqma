import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../../location/domain/entities/location_coordinates.dart';
import '../../domain/entities/address_label.dart';

enum AddressFormStatus { initial, editing, submitting, success, failure }

class AddressFormState extends Equatable {
  const AddressFormState({
    required this.coordinates,
    this.title = '',
    this.district = '',
    this.city = '',
    this.details = '',
    this.label = AddressLabel.home,
    this.isDefault = true,
    this.status = AddressFormStatus.initial,
    this.titleError,
    this.districtError,
    this.cityError,
    this.detailsError,
    this.failure,
  });

  final LocationCoordinates coordinates;
  final String title;
  final String district;
  final String city;
  final String details;
  final AddressLabel label;
  final bool isDefault;
  final AddressFormStatus status;
  final ValidationErrorKey? titleError;
  final ValidationErrorKey? districtError;
  final ValidationErrorKey? cityError;
  final ValidationErrorKey? detailsError;
  final Failure? failure;

  bool get isSubmitting => status == AddressFormStatus.submitting;
  bool get isSuccess => status == AddressFormStatus.success;
  bool get isFailure => status == AddressFormStatus.failure;
  bool get hasValidationErrors =>
      titleError != null ||
      districtError != null ||
      cityError != null ||
      detailsError != null;

  AddressFormState copyWith({
    LocationCoordinates? coordinates,
    String? title,
    String? district,
    String? city,
    String? details,
    AddressLabel? label,
    bool? isDefault,
    AddressFormStatus? status,
    ValidationErrorKey? titleError,
    ValidationErrorKey? districtError,
    ValidationErrorKey? cityError,
    ValidationErrorKey? detailsError,
    Failure? failure,
    bool clearTitleError = false,
    bool clearDistrictError = false,
    bool clearCityError = false,
    bool clearDetailsError = false,
    bool clearFailure = false,
  }) {
    return AddressFormState(
      coordinates: coordinates ?? this.coordinates,
      title: title ?? this.title,
      district: district ?? this.district,
      city: city ?? this.city,
      details: details ?? this.details,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
      status: status ?? this.status,
      titleError: clearTitleError ? null : (titleError ?? this.titleError),
      districtError:
          clearDistrictError ? null : (districtError ?? this.districtError),
      cityError: clearCityError ? null : (cityError ?? this.cityError),
      detailsError:
          clearDetailsError ? null : (detailsError ?? this.detailsError),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        coordinates,
        title,
        district,
        city,
        details,
        label,
        isDefault,
        status,
        titleError,
        districtError,
        cityError,
        detailsError,
        failure,
      ];
}
