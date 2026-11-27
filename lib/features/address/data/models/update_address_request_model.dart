import '../../domain/entities/address_draft.dart';
import '../../domain/entities/address_label.dart';
import '../mappers/address_label_mapper.dart';

/// Body of `PUT /api/Address/Update/{id}`.
///
/// The documented payload is identical to Create, so both requests are built
/// from the same [AddressDraft]; keeping a separate model makes the endpoint's
/// contract explicit and lets either evolve independently.
final class UpdateAddressRequestModel {
  const UpdateAddressRequestModel({
    required this.label,
    required this.title,
    required this.district,
    required this.city,
    required this.details,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  factory UpdateAddressRequestModel.fromDomain(AddressDraft address) {
    return UpdateAddressRequestModel(
      label: address.label,
      title: address.title,
      district: address.district,
      city: address.city,
      details: address.details,
      latitude: address.latitude,
      longitude: address.longitude,
      isDefault: address.isDefault,
    );
  }

  final AddressLabel label;
  final String title;
  final String district;
  final String city;
  final String details;
  final double latitude;
  final double longitude;
  final bool isDefault;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': AddressLabelMapper.toApiValue(label),
        'title': title,
        'district': district,
        'city': city,
        'details': details,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };
}
