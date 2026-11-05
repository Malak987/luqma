import '../entities/address_draft.dart';
import '../repositories/address_repository.dart';

class CreateAddressUseCase {
  const CreateAddressUseCase(this._repository);

  final AddressRepository _repository;

  Future<void> call({required AddressDraft address}) {
    return _repository.createAddress(address);
  }
}
