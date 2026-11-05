import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_draft.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/create_address_use_case.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';

void main() {
  group('GetMyAddressesUseCase', () {
    test('returns the repository address list', () async {
      final address = _address();
      final repository = _FakeAddressRepository(addresses: <Address>[address]);

      final result = await GetMyAddressesUseCase(repository)();

      expect(result, <Address>[address]);
      expect(repository.getMyAddressesCalls, 1);
    });

    test('propagates repository failures unchanged', () async {
      const failure = FailureException(
        Failure(FailureCode.network, debugMessage: 'offline'),
      );
      final repository = _FakeAddressRepository(
        addresses: <Address>[],
        failureException: failure,
      );

      await expectLater(
        GetMyAddressesUseCase(repository)(),
        throwsA(same(failure)),
      );
    });
  });

  group('CreateAddressUseCase', () {
    test('forwards the typed draft including isDefault', () async {
      final repository = _FakeAddressRepository(addresses: <Address>[]);
      final draft = _draft(isDefault: true);

      await CreateAddressUseCase(repository)(address: draft);

      expect(repository.createAddressCalls, <AddressDraft>[draft]);
      expect(repository.createAddressCalls.single.isDefault, isTrue);
    });

    test('propagates repository failures unchanged', () async {
      const failure = FailureException(
        Failure(FailureCode.validation, debugMessage: 'rejected'),
      );
      final repository = _FakeAddressRepository(
        addresses: <Address>[],
        failureException: failure,
      );

      await expectLater(
        CreateAddressUseCase(repository)(address: _draft()),
        throwsA(same(failure)),
      );
    });
  });
}

Address _address() => const Address(
      id: '0ae79d3a-594c-4852-aedf-27d5c176fa70',
      label: AddressLabel.home,
      title: 'Home',
      district: 'District',
      city: 'City',
      details: 'Building 2',
      latitude: 26.557,
      longitude: 31.694,
      isDefault: true,
    );

AddressDraft _draft({bool isDefault = false}) => AddressDraft(
      label: AddressLabel.other,
      title: 'Other place',
      district: 'District',
      city: 'City',
      details: 'Near the shop',
      latitude: 26.557,
      longitude: 31.694,
      isDefault: isDefault,
    );

class _FakeAddressRepository implements AddressRepository {
  _FakeAddressRepository({
    required this.addresses,
    this.failureException,
  });

  final List<Address> addresses;
  final FailureException? failureException;
  int getMyAddressesCalls = 0;
  final List<AddressDraft> createAddressCalls = <AddressDraft>[];

  @override
  Future<List<Address>> getMyAddresses() async {
    getMyAddressesCalls++;
    _throwIfFailed();
    return addresses;
  }

  @override
  Future<void> createAddress(AddressDraft address) async {
    createAddressCalls.add(address);
    _throwIfFailed();
  }

  void _throwIfFailed() {
    if (failureException != null) {
      throw failureException!;
    }
  }
}
