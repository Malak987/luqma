import '../entities/address.dart';
import '../entities/address_draft.dart';

abstract interface class AddressRepository {
  Future<List<Address>> getMyAddresses();

  /// Creates an address. The confirmed Create response payload is not available
  /// in the repository, so this operation does not claim to return an Address.
  Future<void> createAddress(AddressDraft address);
}
