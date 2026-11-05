import '../../../../core/error/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_data_source.dart';
import '../models/create_address_request_model.dart';

class AddressRepositoryImpl implements AddressRepository {
  const AddressRepositoryImpl(this._remoteDataSource);

  final AddressRemoteDataSource _remoteDataSource;

  @override
  Future<List<Address>> getMyAddresses() async {
    try {
      final models = await _remoteDataSource.getMyAddresses();
      return models.map((model) => model.toDomain()).toList(growable: false);
    } on RemoteException catch (error) {
      throw _toFailureException(error);
    } on FailureException {
      rethrow;
    } catch (_) {
      throw const FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: 'Get my addresses could not be completed',
        ),
      );
    }
  }

  @override
  Future<void> createAddress(AddressDraft address) async {
    try {
      await _remoteDataSource.createAddress(
        CreateAddressRequestModel.fromDomain(address),
      );
    } on RemoteException catch (error) {
      throw _toFailureException(error);
    } on FailureException {
      rethrow;
    } catch (_) {
      throw const FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: 'Create address could not be completed',
        ),
      );
    }
  }

  FailureException _toFailureException(RemoteException error) {
    return FailureException(
      Failure(
        error.code,
        debugMessage: error.message,
      ),
    );
  }
}
