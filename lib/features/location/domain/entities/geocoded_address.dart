import 'package:equatable/equatable.dart';

/// Provider-independent address components for a coordinate lookup.
///
/// Every component is optional because a provider may return only partial
/// information. A repository's `null` result represents no match; unknown
/// components must remain null rather than being inferred.
final class GeocodedAddress extends Equatable {
  const GeocodedAddress({
    this.formattedAddress,
    this.houseNumber,
    this.street,
    this.district,
    this.city,
    this.region,
    this.country,
    this.postalCode,
  });

  final String? formattedAddress;
  final String? houseNumber;
  final String? street;
  final String? district;
  final String? city;
  final String? region;
  final String? country;
  final String? postalCode;

  bool get hasAnyComponent => <String?>[
        formattedAddress,
        houseNumber,
        street,
        district,
        city,
        region,
        country,
        postalCode,
      ].any((String? value) => value?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => <Object?>[
        formattedAddress,
        houseNumber,
        street,
        district,
        city,
        region,
        country,
        postalCode,
      ];
}
