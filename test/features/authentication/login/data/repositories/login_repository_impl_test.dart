import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/authentication/login/data/datasources/login_remote_data_source.dart';
import 'package:luqma_app/features/authentication/login/data/models/login_request_model.dart';
import 'package:luqma_app/features/authentication/login/data/models/login_response_model.dart';
import 'package:luqma_app/features/authentication/login/data/repositories/login_repository_impl.dart';

void main() {
  group('LoginRepositoryImpl', () {
    test('maps the response to AuthSession and persists the session', () async {
      final remoteDataSource = _FakeLoginRemoteDataSource(_validResponse());
      final storage = _FakeSecureStorageService();
      final repository = LoginRepositoryImpl(remoteDataSource, storage);

      final session = await repository.login(
        email: '  person@example.test  ',
        password: 'not-a-real-password',
      );

      expect(session.userId, 'user-123');
      expect(session.userName, 'Test User');
      expect(session.role, 'User');
      expect(session.expiresAt.isUtc, isTrue);
      expect(remoteDataSource.receivedRequest?.email, 'person@example.test');
      expect(
        remoteDataSource.receivedRequest?.password,
        'not-a-real-password',
      );
      expect(storage.savedData?['userId'], 'user-123');
      expect(storage.savedData?['token'], 'test-token-not-real');
      expect(storage.savedData?['expiresAt'], '2027-08-06T12:25:06.462797Z');
    });

    test('maps remote failures into the application failure abstraction',
        () async {
      final remoteDataSource = _FakeLoginRemoteDataSource(
        null,
        remoteException: const RemoteException(
          code: FailureCode.invalidCredentials,
          message: 'HTTP 401',
        ),
      );
      final repository = LoginRepositoryImpl(
        remoteDataSource,
        _FakeSecureStorageService(),
      );

      await expectLater(
        repository.login(
          email: 'person@example.test',
          password: 'not-a-real-password',
        ),
        throwsA(
          isA<FailureException>().having(
            (error) => error.failure.code,
            'failure code',
            FailureCode.invalidCredentials,
          ),
        ),
      );
    });

    test('clears storage if persisting a session fails', () async {
      final storage = _FakeSecureStorageService(failSave: true);
      final repository = LoginRepositoryImpl(
        _FakeLoginRemoteDataSource(_validResponse()),
        storage,
      );

      await expectLater(
        repository.login(
          email: 'person@example.test',
          password: 'not-a-real-password',
        ),
        throwsA(
          isA<FailureException>().having(
            (error) => error.failure.code,
            'failure code',
            FailureCode.unknown,
          ),
        ),
      );

      expect(storage.clearCalled, isTrue);
      expect(storage.savedData, isNull);
    });
  });
}

LoginResponseModel _validResponse() => LoginResponseModel.fromJson(
      <String, dynamic>{
        'userId': 'user-123',
        'userName': 'Test User',
        'role': 'User',
        'token': 'test-token-not-real',
        'expiresAt': '2027-08-06T12:25:06.4627977Z',
      },
    );

class _FakeLoginRemoteDataSource implements LoginRemoteDataSource {
  _FakeLoginRemoteDataSource(
    this.response, {
    this.remoteException,
  });

  final LoginResponseModel? response;
  final RemoteException? remoteException;
  LoginRequestModel? receivedRequest;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    receivedRequest = request;
    if (remoteException != null) {
      throw remoteException!;
    }
    return response!;
  }
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.failSave = false})
      : super(const FlutterSecureStorage());

  final bool failSave;
  Map<String, String>? savedData;
  bool clearCalled = false;

  @override
  Future<void> saveAuthData({
    required String token,
    required String userId,
    required String userName,
    required String role,
    required String expiresAt,
  }) async {
    savedData = <String, String>{
      'token': token,
      'userId': userId,
      'userName': userName,
      'role': role,
      'expiresAt': expiresAt,
    };
    if (failSave) {
      throw StateError('Injected storage failure');
    }
  }

  @override
  Future<void> clearAuthData() async {
    clearCalled = true;
    savedData = null;
  }
}
