import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/authentication/password_reset/data/models/password_reset_failure_parser.dart';

void main() {
  group('PasswordResetFailureParser.parse', () {
    test('reads the real unknown-email envelope and keeps the Arabic message',
        () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'message': 'البريد الإلكتروني غير موجود',
        'data': null,
        'isSucceeded': false,
        'timestamp': '2026-10-07T07:55:01.0000000Z',
      });

      expect(message, 'البريد الإلكتروني غير موجود');
    });

    test('reads the real invalid/expired OTP envelope', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'message': 'رمز التحقق غير صحيح أو منتهي الصلاحية',
        'data': null,
        'isSucceeded': false,
      });

      expect(message, 'رمز التحقق غير صحيح أو منتهي الصلاحية');
    });

    test('ignores an envelope that does not report failure', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'message': 'تم الإرسال',
        'data': '',
        'isSucceeded': true,
      });

      expect(message, isNull,
          reason: 'a successful envelope is not a failure message');
    });

    test('reads a single-string `errors` entry', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{'message': 'خطأ عام'},
      });

      expect(message, 'خطأ عام');
    });

    test('reads a list-valued `errors` entry', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{
          '\$.newPassword': <dynamic>['كلمة المرور قصيرة'],
        },
      });

      expect(message, 'كلمة المرور قصيرة');
    });

    test('reads a PascalCase key, as ASP.NET emits for a missing field', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{
          'Otp': <dynamic>['The Otp field is required.'],
        },
      });

      expect(message, 'The Otp field is required.');
    });

    test('walks `errors` by value, so key casing never matters', () {
      final dotted = PasswordResetFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{
          'request': <dynamic>['The request field is required.'],
        },
      });
      final pascal = PasswordResetFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{
          'Request': <dynamic>['The request field is required.'],
        },
      });

      expect(dotted, 'The request field is required.');
      expect(pascal, dotted);
    });

    test('joins multiple `errors` entries', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{
          'email': <dynamic>['البريد مطلوب'],
          'otp': <dynamic>['الرمز مطلوب'],
        },
      });

      expect(message, contains('البريد مطلوب'));
      expect(message, contains('الرمز مطلوب'));
    });

    test('ignores empty entries inside an `errors` list', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{
          'otp': <dynamic>['', '   ', 'الرمز مطلوب'],
        },
      });

      expect(message, 'الرمز مطلوب');
    });

    test('prefixes the ProblemDetails title when one is present', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'errors': <String, dynamic>{
          '\$.newPassword': <dynamic>['The JSON value could not be converted'],
        },
      });

      expect(message, contains('One or more validation errors occurred.'));
      expect(message, contains('The JSON value could not be converted'));
    });

    test('does not invent a message from a title alone', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'title': 'One or more validation errors occurred.',
        'status': 400,
      });

      expect(message, isNull,
          reason: 'without an `errors` member this is not a parseable body');
    });

    test('prefers the envelope message over ProblemDetails fields', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'message': 'البريد الإلكتروني غير موجود',
        'isSucceeded': false,
        'title': 'Bad Request',
        'errors': <String, dynamic>{'x': <dynamic>['should not win']},
      });

      expect(message, 'البريد الإلكتروني غير موجود');
    });

    test('ignores a blank envelope message and falls through', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'message': '   ',
        'isSucceeded': false,
        'errors': <String, dynamic>{'otp': <dynamic>['الرمز مطلوب']},
      });

      expect(message, 'الرمز مطلوب');
    });

    test('returns null for an empty or unreadable body', () {
      expect(PasswordResetFailureParser.parse(const <String, dynamic>{}), isNull);
      expect(PasswordResetFailureParser.parse('a bare string'), isNull);
      expect(PasswordResetFailureParser.parse(null), isNull);
      expect(PasswordResetFailureParser.parse(42), isNull);
    });

    test('returns null for an `errors` member holding no strings', () {
      final message = PasswordResetFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{'otp': <dynamic>[1, 2]},
      });

      expect(message, isNull);
    });

    test('reads a map with non-String static type', () {
      final message = PasswordResetFailureParser.parse(<Object?, Object?>{
        'message': 'البريد الإلكتروني غير موجود',
        'isSucceeded': false,
      });

      expect(message, 'البريد الإلكتروني غير موجود');
    });
  });
}
