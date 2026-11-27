import '../entities/address.dart';
import '../entities/address_draft.dart';
import '../repositories/address_repository.dart';

class UpdateAddressUseCase {
  const UpdateAddressUseCase(this._repository);

  final AddressRepository _repository;

  Future<Address> call({required String id, required AddressDraft address}) {
    return _repository.updateAddress(id: id, address: address);
  }
}
