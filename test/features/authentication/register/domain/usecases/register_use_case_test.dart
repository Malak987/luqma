import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/authentication/register/domain/entities/register_result.dart';
import 'package:luqma_app/features/authentication/register/domain/repositories/register_repository.dart';
import 'package:luqma_app/features/authentication/register/domain/usecases/register_use_case.dart';

void main() {
  group('RegisterUseCase', () {
    test('forwards every field to the repository and returns its result',
        () async {
      final repository = _FakeRegisterRepository(
        const RegisterResult(message: 'Account created'),
      );

      final result = await RegisterUseCase(repository).call(
        userName: 'new_user',
        email: 'person@example.test',
        password: 'not-a-real-password',
        confirmPassword: 'not-a-real-password',
        phoneNumber: '01000000000',
        address: '1 Test Street',
      );

      expect(result, const RegisterResult(message: 'Account created'));
      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.userName, 'new_user');
      expect(repository.calls.single.email, 'person@example.test');
      expect(repository.calls.single.password, 'not-a-real-password');
      expect(repository.calls.single.confirmPassword, 'not-a-real-password');
      expect(repository.calls.single.phoneNumber, '01000000000');
      expect(repository.calls.single.address, '1 Test Street');
    });

    test('propagates a failure from the repository without wrapping it',
        () async {
      const failure = FailureException(
        Failure(FailureCode.validation, debugMessage: 'duplicate email'),
      );
      final repository = _FakeRegisterRepository(null, failureException: failure);

      await expectLater(
        RegisterUseCase(repository).call(
          userName: 'new_user',
          email: 'person@example.test',
          password: 'pw',
          confirmPassword: 'pw',
          phoneNumber: '01000000000',
          address: '1 Test Street',
        ),
        throwsA(same(failure)),
      );
    });
  });
}

class _RegisterCall {
  const _RegisterCall({
    required this.userName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
    required this.address,
  });

  final String userName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phoneNumber;
  final String address;
}

class _FakeRegisterRepository implements RegisterRepository {
  _FakeRegisterRepository(this.result, {this.failureException});

  final RegisterResult? result;
  final FailureException? failureException;
  final List<_RegisterCall> calls = <_RegisterCall>[];

  @override
  Future<RegisterResult> register({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String address,
  }) async {
    calls.add(
      _RegisterCall(
        userName: userName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber,
        address: address,
      ),
    );

    if (failureException != null) {
      throw failureException!;
    }
    return result!;
  }
}
