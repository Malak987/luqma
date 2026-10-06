import '../../../../../core/error/failures.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/login_entity.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../datasources/login_remote_data_source.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  const AuthenticationRepositoryImpl(
      this._remoteDataSource,
      this._secureStorageService,
      );

  final LoginRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorageService;

  @override
  Future<LoginEntity> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final loginEntity = await _remoteDataSource.login(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );

      await _secureStorageService.saveAuthData(
        token: loginEntity.token,
        userId: loginEntity.userId,
        userName: loginEntity.username,
        role: loginEntity.role,
        expiresAt: loginEntity.expiresAt,
      );

      return loginEntity;
    } on RemoteException catch (error) {
      throw FailureException(
        Failure(
          error.code,
          debugMessage: error.message,
        ),
      );
    } on FailureException {
      rethrow;
    } catch (error) {
      throw FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: error.toString(),
        ),
      );
    }
  }
}