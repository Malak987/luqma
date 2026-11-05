import 'package:equatable/equatable.dart';

import 'address_label.dart';

/// A persisted address returned by the Address API.
class Address extends Equatable {
  const Address({
    required this.id,
    required this.label,
    required this.title,
    required this.district,
    required this.city,
    required this.details,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  final String id;
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
        id,
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
