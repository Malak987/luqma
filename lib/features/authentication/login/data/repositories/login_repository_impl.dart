import '../../../../../core/error/failures.dart';
import '../../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/login_repository.dart';
import '../datasources/login_remote_data_source.dart';
import '../mappers/login_mapper.dart';
import '../models/login_request_model.dart';

class LoginRepositoryImpl implements LoginRepository {
  const LoginRepositoryImpl(
    this._remoteDataSource,
    this._secureStorageService,
  );

  final LoginRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorageService;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final responseModel = await _remoteDataSource.login(
        LoginRequestModel(
          email: email.trim(),
          password: password,
        ),
      );
      final session = LoginMapper.toDomain(responseModel);

      try {
        await _secureStorageService.saveAuthData(
          token: session.token,
          userId: session.userId,
          userName: session.userName,
          role: session.role,
          expiresAt: session.expiresAt.toUtc().toIso8601String(),
        );
      } catch (_) {
        try {
          await _secureStorageService.clearAuthData();
        } catch (_) {
          // Preserve the original persistence error for failure mapping.
        }
        rethrow;
      }

      return session;
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
      throw const FailureException(
        Failure(
          FailureCode.unknown,
          debugMessage: 'Login could not be completed',
        ),
      );
    }
  }
}
