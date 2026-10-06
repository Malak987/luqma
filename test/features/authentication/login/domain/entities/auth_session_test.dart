import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/authentication/login/domain/entities/auth_session.dart';

void main() {
  test('AuthSession does not reveal its token in string output', () {
    final session = AuthSession(
      userId: 'user-123',
      userName: 'Test User',
      role: 'User',
      token: 'test-token-not-real',
      expiresAt: DateTime.utc(2027, 8, 6, 12, 25),
    );

    expect(session.toString(), isNot(contains('test-token-not-real')));
  });
}
