import '../../domain/entities/address.dart';
import '../../domain/entities/address_label.dart';
import '../mappers/address_label_mapper.dart';

final class AddressModel {
  const AddressModel({
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

  factory AddressModel.fromJson(Object? json) {
    final map = _asStringKeyedMap(json, 'Address');
    final id = _requiredString(map, 'id');
    if (id.trim().isEmpty) {
      throw const FormatException('Missing or invalid required field: id');
    }

    return AddressModel(
      id: id,
      label: AddressLabelMapper.fromApiValue(map['label']),
      title: _requiredString(map, 'title'),
      district: _requiredString(map, 'district'),
      city: _requiredString(map, 'city'),
      details: _requiredString(map, 'details'),
      latitude: _requiredDouble(map, 'latitude'),
      longitude: _requiredDouble(map, 'longitude'),
      isDefault: _requiredBool(map, 'isDefault'),
    );
  }

  Address toDomain() => Address(
        id: id,
        label: label,
        title: title,
        district: district,
        city: city,
        details: details,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );
}

Map<String, dynamic> _asStringKeyedMap(Object? value, String description) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map<Object?, Object?>) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('Invalid $description response');
      }
      result[key] = entry.value;
    }
    return result;
  }

  throw FormatException('Invalid $description response');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Missing or invalid required field: $key');
  }
  return value;
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw FormatException('Missing or invalid required field: $key');
  }
  return value.toDouble();
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Missing or invalid required field: $key');
  }
  return value;
}
