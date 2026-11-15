import 'package:equatable/equatable.dart';

import 'address_label.dart';

/// The typed input required to create an address.
///
/// [isDefault] is explicit so the first saved address can be created as the
/// default without relying on API-side implicit behavior.
class AddressDraft extends Equatable {
  const AddressDraft({
    required this.label,
    required this.title,
    required this.district,
    required this.city,
    required this.details,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  final AddressLabel label;
  final String title;
  final String district;
  final String city;
  final String details;
  final double latitude;
  final double longitude;
  final bool isDefault;

  @override
  List<Object> get props => <Object>[
        label,
        title,
        district,
        city,
        details,
        latitude,
        longitude,
        isDefault,
      ];
}
