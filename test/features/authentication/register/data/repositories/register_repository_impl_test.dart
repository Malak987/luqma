import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/authentication/register/data/datasources/register_remote_data_source.dart';
import 'package:luqma_app/features/authentication/register/data/models/register_request_model.dart';
import 'package:luqma_app/features/authentication/register/data/models/register_response_model.dart';
import 'package:luqma_app/features/authentication/register/data/repositories/register_repository_impl.dart';
import 'package:luqma_app/features/authentication/register/domain/entities/register_result.dart';

void main() {
  group('RegisterRepositoryImpl', () {
    test('builds the request from domain input and maps the response',
        () async {
      final remoteDataSource = _FakeRegisterRemoteDataSource(
        const RegisterResponseModel(message: 'Account created'),
      );
      final repository = RegisterRepositoryImpl(remoteDataSource);

      final result = await repository.register(
        userName: '  new_user  ',
        email: '  person@example.test  ',
        password: 'not-a-real-password',
        confirmPassword: 'not-a-real-password',
        phoneNumber: '  01000000000  ',
        address: '  1 Test Street  ',
      );

      expect(result, const RegisterResult(message: 'Account created'));
      expect(remoteDataSource.receivedRequest?.userName, 'new_user');
      expect(remoteDataSource.receivedRequest?.email, 'person@example.test');
      expect(remoteDataSource.receivedRequest?.phoneNumber, '01000000000');
      expect(remoteDataSource.receivedRequest?.address, '1 Test Street');
    });

    test('never sends a password in trimmed form but does trim identifiers',
        () async {
      final remoteDataSource = _FakeRegisterRemoteDataSource(
        const RegisterResponseModel(message: 'ok'),
      );

      await RegisterRepositoryImpl(remoteDataSource).register(
        userName: 'new_user',
        email: 'person@example.test',
        password: '  padded-password  ',
        confirmPassword: '  padded-password  ',
        phoneNumber: '01000000000',
        address: '1 Test Street',
      );

      expect(
        remoteDataSource.receivedRequest?.password,
        '  padded-password  ',
      );
      expect(
        remoteDataSource.receivedRequest?.confirmPassword,
        '  padded-password  ',
      );
    });

    test('always requests the default customer role', () async {
      final remoteDataSource = _FakeRegisterRemoteDataSource(
        const RegisterResponseModel(message: 'ok'),
      );

      await RegisterRepositoryImpl(remoteDataSource).register(
        userName: 'new_user',
        email: 'person@example.test',
        password: 'pw',
        confirmPassword: 'pw',
        phoneNumber: '01000000000',
        address: '1 Test Street',
      );

      expect(
        remoteDataSource.receivedRequest?.toJson()['role'],
        RegisterRequestModel.defaultRole,
      );
    });

    test('maps a remote failure into the application failure abstraction '
        'and keeps the backend message', () async {
      final remoteDataSource = _FakeRegisterRemoteDataSource(
        null,
        remoteException: const RemoteException(
          code: FailureCode.validation,
          message: 'هذا البريد مستخدم بالفعل',
        ),
      );

      await expectLater(
        RegisterRepositoryImpl(remoteDataSource).register(
          userName: 'new_user',
          email: 'person@example.test',
          password: 'pw',
          confirmPassword: 'pw',
          phoneNumber: '01000000000',
          address: '1 Test Street',
        ),
        throwsA(
          isA<FailureException>()
              .having(
                (error) => error.failure.code,
                'failure code',
                FailureCode.validation,
              )
              .having(
                (error) => error.failure.debugMessage,
                'debug message',
                'هذا البريد مستخدم بالفعل',
              ),
        ),
      );
    });

    test('propagates a network failure unchanged', () async {
      final remoteDataSource = _FakeRegisterRemoteDataSource(
        null,
        remoteException: const RemoteException(
          code: FailureCode.network,
          message: 'Network request failed',
        ),
      );

      await expectLater(
        RegisterRepositoryImpl(remoteDataSource).register(
          userName: 'new_user',
          email: 'person@example.test',
          password: 'pw',
          confirmPassword: 'pw',
          phoneNumber: '01000000000',
          address: '1 Test Street',
        ),
        throwsA(
          isA<FailureException>().having(
            (error) => error.failure.code,
            'failure code',
            FailureCode.network,
          ),
        ),
      );
    });

    test('rethrows an existing FailureException untouched', () async {
      const original = FailureException(
        Failure(FailureCode.invalidCredentials, debugMessage: 'original'),
      );
      final remoteDataSource = _FakeRegisterRemoteDataSource(
        null,
        failureException: original,
      );

      await expectLater(
        RegisterRepositoryImpl(remoteDataSource).register(
          userName: 'new_user',
          email: 'person@example.test',
          password: 'pw',
          confirmPassword: 'pw',
          phoneNumber: '01000000000',
          address: '1 Test Street',
        ),
        throwsA(same(original)),
      );
    });

    test('converts an unexpected error without leaking the password',
        () async {
      final remoteDataSource = _FakeRegisterRemoteDataSource(
        null,
        unexpectedError: StateError('boom with not-a-real-password inside'),
      );

      await expectLater(
        RegisterRepositoryImpl(remoteDataSource).register(
          userName: 'new_user',
          email: 'person@example.test',
          password: 'not-a-real-password',
          confirmPassword: 'not-a-real-password',
          phoneNumber: '01000000000',
          address: '1 Test Street',
        ),
        throwsA(
          isA<FailureException>()
              .having(
                (error) => error.failure.code,
                'failure code',
                FailureCode.unknown,
              )
              .having(
                (error) => error.failure.debugMessage,
                'debug message',
                isNot(contains('not-a-real-password')),
              ),
        ),
      );
    });
  });
}

class _FakeRegisterRemoteDataSource implements RegisterRemoteDataSource {
  _FakeRegisterRemoteDataSource(
    this.response, {
    this.remoteException,
    this.failureException,
    this.unexpectedError,
  });

  final RegisterResponseModel? response;
  final RemoteException? remoteException;
  final FailureException? failureException;
  final Object? unexpectedError;
  RegisterRequestModel? receivedRequest;

  @override
  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    receivedRequest = request;
    if (remoteException != null) {
      throw remoteException!;
    }
    if (failureException != null) {
      throw failureException!;
    }
    if (unexpectedError != null) {
      throw unexpectedError!;
    }
    return response!;
  }
}
