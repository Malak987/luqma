import '../entities/address.dart';
import '../repositories/address_repository.dart';

class GetMyAddressesUseCase {
  const GetMyAddressesUseCase(this._repository);

  final AddressRepository _repository;

  Future<List<Address>> call() => _repository.getMyAddresses();
}
