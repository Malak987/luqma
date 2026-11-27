import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/address.dart';
import '../../domain/entities/address_label.dart';
import '../../domain/repositories/address_snapshot_cache.dart';

/// SharedPreferences-backed [AddressSnapshotCache]. It is cleared whenever the
/// session ends, so one customer's addresses are never shown to another.
class AddressSnapshotCacheImpl implements AddressSnapshotCache {
  AddressSnapshotCacheImpl(this._preferences);

  final SharedPreferences _preferences;
  static const String _key = 'address_snapshot_v1';

  @override
  AddressSnapshot? read() {
    try {
      final raw = _preferences.getString(_key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final items = decoded['items'];
      if (items is! List || items.isEmpty) return null;
      final addresses = items.map(_decode).toList(growable: false);
      final selected = decoded['selectedAddressId'];
      return AddressSnapshot(
        addresses: List<Address>.unmodifiable(addresses),
        selectedAddressId: selected is String && selected.isNotEmpty
            ? selected
            : null,
      );
    } catch (_) {
      return null; // A damaged cache is a miss, never an empty address list.
    }
  }

  @override
  Future<void> write(List<Address> addresses, String? selectedAddressId) async {
    if (addresses.isEmpty) {
      await clear();
      return;
    }
    try {
      await _preferences.setString(
        _key,
        jsonEncode(<String, Object?>{
          'selectedAddressId': selectedAddressId,
          'items': addresses.map(_encode).toList(growable: false),
        }),
      );
    } catch (_) {
      // Caching is an optimisation; a failed write must never break the app.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _preferences.remove(_key);
    } catch (_) {}
  }

  static Map<String, Object?> _encode(Address a) => <String, Object?>{
        'id': a.id,
        'label': a.label.name,
        'title': a.title,
        'district': a.district,
        'city': a.city,
        'details': a.details,
        'latitude': a.latitude,
        'longitude': a.longitude,
        'isDefault': a.isDefault,
      };

  static Address _decode(Object? value) {
    final map = value as Map<String, dynamic>;
    final id = map['id'] as String;
    if (id.trim().isEmpty) throw const FormatException('empty id');
    return Address(
      id: id,
      label: AddressLabel.values.byName(map['label'] as String),
      title: map['title'] as String,
      district: map['district'] as String,
      city: map['city'] as String,
      details: map['details'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      isDefault: map['isDefault'] as bool,
    );
  }
}
