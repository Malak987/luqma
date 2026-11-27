import '../entities/address.dart';

/// The last addresses the server confirmed for the signed-in customer, kept so
/// the next app launch can open Home immediately and refresh in the background.
class AddressSnapshot {
  const AddressSnapshot({required this.addresses, this.selectedAddressId});

  final List<Address> addresses;
  final String? selectedAddressId;
}

/// A null read means "no valid snapshot" (never saved, cleared on logout, or
/// damaged); an empty snapshot is never stored, so the "no address yet" setup
/// flow always comes from the server.
abstract interface class AddressSnapshotCache {
  AddressSnapshot? read();
  Future<void> write(List<Address> addresses, String? selectedAddressId);
  Future<void> clear();
}
