import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/authentication/login/data/models/login_response_model.dart';

void main() {
  group('LoginResponseModel', () {
    test('parses the required fields and seven-digit UTC timestamp', () {
      final model = LoginResponseModel.fromJson(_validResponse());

      expect(model.userId, 'user-123');
      expect(model.userName, 'Malak Ezat');
      expect(model.role, 'User');
      expect(model.token, 'test-token-not-real');
      expect(model.expiresAt.isUtc, isTrue);
      expect(model.expiresAt.millisecond, 462);
      expect(model.expiresAt.microsecond, 797);
    });

    test('rejects a missing token', () {
      final response = _validResponse()..remove('token');

      expect(
        () => LoginResponseModel.fromJson(response),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing userId', () {
      final response = _validResponse()..remove('userId');

      expect(
        () => LoginResponseModel.fromJson(response),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an invalid expiresAt value', () {
      final response = _validResponse()..['expiresAt'] = 'not-a-date';

      expect(
        () => LoginResponseModel.fromJson(response),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects required fields with an invalid type', () {
      final response = _validResponse()..['role'] = 7;

      expect(
        () => LoginResponseModel.fromJson(response),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _validResponse() => <String, dynamic>{
      'userId': 'user-123',
      'userName': 'Malak Ezat',
      'role': 'User',
      'token': 'test-token-not-real',
      'expiresAt': '2027-08-06T12:25:06.4627977Z',
    };
