import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/address/data/datasources/address_remote_data_source.dart';
import 'package:luqma_app/features/address/data/models/address_model.dart';
import 'package:luqma_app/features/address/data/models/create_address_request_model.dart';
import 'package:luqma_app/features/address/data/repositories/address_repository_impl.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_draft.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';

void main() {
  group('AddressRepositoryImpl', () {
    test('maps remote address models to domain entities', () async {
      final remote = _FakeAddressRemoteDataSource(
        addresses: <AddressModel>[_addressModel()],
      );

      final addresses = await AddressRepositoryImpl(remote).getMyAddresses();

      expect(addresses, <Address>[_addressModel().toDomain()]);
      expect(remote.getMyAddressesCalls, 1);
    });

    test('passes an empty successful list through as empty', () async {
      final addresses = await AddressRepositoryImpl(
        _FakeAddressRemoteDataSource(addresses: <AddressModel>[]),
      ).getMyAddresses();

      expect(addresses, isEmpty);
    });

    test('maps a remote failure into FailureException without losing its code',
        () async {
      final repository = AddressRepositoryImpl(
        _FakeAddressRemoteDataSource(
          addresses: <AddressModel>[],
          remoteException: const RemoteException(
            code: FailureCode.network,
            message: 'Network request failed',
          ),
        ),
      );

      await expectLater(
        repository.getMyAddresses(),
        throwsA(
          isA<FailureException>()
              .having(
                (error) => error.failure.code,
                'failure code',
                FailureCode.network,
              )
              .having(
                (error) => error.failure.debugMessage,
                'debug message',
                'Network request failed',
              ),
        ),
      );
    });

    test('maps a create request from the typed domain draft', () async {
      final remote = _FakeAddressRemoteDataSource(addresses: <AddressModel>[]);
      final draft = _draft(isDefault: true);

      await AddressRepositoryImpl(remote).createAddress(draft);

      expect(
        remote.createRequest?.toJson(),
        <String, dynamic>{
          'label': 0,
          'title': 'Home title',
          'district': 'District',
          'city': 'City',
          'details': 'Building 2',
          'latitude': 26.557,
          'longitude': 31.694,
          'isDefault': true,
        },
      );
    });

    test('maps Create remote failures into repository failures', () async {
      final repository = AddressRepositoryImpl(
        _FakeAddressRemoteDataSource(
          addresses: <AddressModel>[],
          remoteException: const RemoteException(
            code: FailureCode.invalidCredentials,
            message: 'Unauthorized',
          ),
        ),
      );

      await expectLater(
        repository.createAddress(_draft()),
        throwsA(
          isA<FailureException>().having(
            (error) => error.failure.code,
            'failure code',
            FailureCode.invalidCredentials,
          ),
        ),
      );
    });
  });
}

AddressModel _addressModel() => const AddressModel(
      id: '0ae79d3a-594c-4852-aedf-27d5c176fa70',
      label: AddressLabel.home,
      title: 'string',
      district: 'string',
      city: 'string',
      details: 'string',
      latitude: 0,
      longitude: 0,
      isDefault: true,
    );

AddressDraft _draft({bool isDefault = false}) => AddressDraft(
      label: AddressLabel.home,
      title: 'Home title',
      district: 'District',
      city: 'City',
      details: 'Building 2',
      latitude: 26.557,
      longitude: 31.694,
      isDefault: isDefault,
    );

class _FakeAddressRemoteDataSource implements AddressRemoteDataSource {
  _FakeAddressRemoteDataSource({
    required this.addresses,
    this.remoteException,
  });

  final List<AddressModel> addresses;
  final RemoteException? remoteException;
  int getMyAddressesCalls = 0;
  CreateAddressRequestModel? createRequest;

  @override
  Future<List<AddressModel>> getMyAddresses() async {
    getMyAddressesCalls++;
    _throwIfFailed();
    return addresses;
  }

  @override
  Future<void> createAddress(CreateAddressRequestModel request) async {
    createRequest = request;
    _throwIfFailed();
  }

  void _throwIfFailed() {
    if (remoteException != null) {
      throw remoteException!;
    }
  }
}
