import '../../domain/entities/address.dart';

/// One-line delivery summary for the Home header: `district, city`.
///
/// The street/details line stays on the address screen; the header keeps the
/// short form so a long detailed address cannot push the header rows apart.
/// Returns an empty string when the address carries no location text at all.
String addressSummaryLine(Address address, {required bool arabic}) {
  final district = address.district.trim();
  final city = address.city.trim();
  final separator = arabic ? '، ' : ', ';
  if (district.isEmpty) return city;
  if (city.isEmpty) return district;
  return '$district$separator$city';
}
