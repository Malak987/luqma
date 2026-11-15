import '../../../../../core/error/failures.dart';
import '../../domain/entities/register_result.dart';
import '../../domain/repositories/register_repository.dart';
import '../datasources/register_remote_data_source.dart';
import '../mappers/register_mapper.dart';
import '../models/register_request_model.dart';

/// Register needs no `SecureStorageService`: the endpoint returns no token,
/// so — unlike Login — there is no session to persist here.
class RegisterRepositoryImpl implements RegisterRepository {
  const RegisterRepositoryImpl(this._remoteDataSource);

  final RegisterRemoteDataSource _remoteDataSource;

  @override
  Future<RegisterResult> register({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      final responseModel = await _remoteDataSource.register(
        RegisterRequestModel(
          userName: userName.trim(),
          email: email.trim(),
          password: password,
          confirmPassword: confirmPassword,
          phoneNumber: phoneNumber.trim(),
          address: address.trim(),
        ),
      );

      return RegisterMapper.toDomain(responseModel);
    } on RemoteException catch (error) {
      throw FailureException(
        Failure(
          error.code,
          debugMessage: error.message,
        ),
      );
    } on FailureException {
      rethrow;
    } catch (_) {
      // Never interpolate the raw error: it can contain the password.
      throw const FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: 'Register could not be completed',
        ),
      );
    }
  }
}
