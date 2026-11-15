import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/authentication/register/data/models/register_failure_parser.dart';
import 'package:luqma_app/features/authentication/register/data/models/register_response_envelope_model.dart';
import 'package:luqma_app/features/authentication/register/data/models/register_response_model.dart';

void main() {
  group('RegisterResponseModel', () {
    test('parses the confirmation string the backend sends as `data`', () {
      final model = RegisterResponseModel.fromJson(
        'تم التسجيل بنجاح، برجاء تأكيد البريد الإلكتروني',
      );

      expect(
        model.message,
        'تم التسجيل بنجاح، برجاء تأكيد البريد الإلكتروني',
      );
    });

    test('trims surrounding whitespace', () {
      final model = RegisterResponseModel.fromJson('  confirmed  ');

      expect(model.message, 'confirmed');
    });

    test('rejects an object payload', () {
      expect(
        () => RegisterResponseModel.fromJson(<String, dynamic>{'a': 'b'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an empty string', () {
      expect(
        () => RegisterResponseModel.fromJson('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects null', () {
      expect(
        () => RegisterResponseModel.fromJson(null),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RegisterResponseEnvelopeModel', () {
    test('parses a successful envelope and keeps the message', () {
      final envelope = RegisterResponseEnvelopeModel.fromJson(<String, dynamic>{
        'message': 'تم التسجيل بنجاح، برجاء تأكيد البريد الإلكتروني',
        'data': 'تم التسجيل بنجاح، برجاء تأكيد البريد الإلكتروني',
        'isSucceeded': true,
        'timestamp': '2027-08-06T12:25:06.4627977Z',
      });

      expect(envelope.isSucceeded, isTrue);
      expect(envelope.data?.message, isNotEmpty);
      expect(envelope.message, isNotNull);
    });

    test('parses a failure envelope without a data payload', () {
      final envelope = RegisterResponseEnvelopeModel.fromJson(<String, dynamic>{
        'message': 'هذا البريد مستخدم بالفعل',
        'data': null,
        'isSucceeded': false,
        'timestamp': '2027-08-06T12:25:06.4627977Z',
      });

      expect(envelope.isSucceeded, isFalse);
      expect(envelope.message, 'هذا البريد مستخدم بالفعل');
      expect(envelope.data, isNull);
    });

    test('normalises a blank message to null', () {
      final envelope = RegisterResponseEnvelopeModel.fromJson(<String, dynamic>{
        'message': '   ',
        'isSucceeded': false,
      });

      expect(envelope.message, isNull);
    });

    test('accepts a map with non-String-typed keys at runtime', () {
      final envelope =
          RegisterResponseEnvelopeModel.fromJson(<Object?, Object?>{
        'message': 'confirmed',
        'isSucceeded': true,
        'data': 'confirmed',
      });

      expect(envelope.isSucceeded, isTrue);
      expect(envelope.data?.message, 'confirmed');
    });

    test('rejects an envelope without a boolean isSucceeded', () {
      expect(
        () => RegisterResponseEnvelopeModel.fromJson(<String, dynamic>{
          'isSucceeded': 'yes',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a payload that is not a map', () {
      expect(
        () => RegisterResponseEnvelopeModel.fromJson('not-an-envelope'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('RegisterFailureParser', () {
    test('reads the message from a failed Luqma envelope', () {
      final message = RegisterFailureParser.parse(<String, dynamic>{
        'message': 'هذا البريد مستخدم بالفعل',
        'data': null,
        'isSucceeded': false,
      });

      expect(message, 'هذا البريد مستخدم بالفعل');
    });

    test('ignores a successful envelope', () {
      final message = RegisterFailureParser.parse(<String, dynamic>{
        'message': 'all good',
        'isSucceeded': true,
      });

      expect(message, isNull);
    });

    test('joins ProblemDetails error entries under the title', () {
      final message = RegisterFailureParser.parse(<String, dynamic>{
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'errors': <String, dynamic>{
          r'$': <String>["'not-json' is an invalid JSON literal."],
          'request': <String>['The request field is required.'],
        },
        'traceId': '00-trace',
      });

      expect(message, contains('One or more validation errors occurred.'));
      expect(message, contains('The request field is required.'));
    });

    test('handles a ProblemDetails body whose errors hold plain strings', () {
      final message = RegisterFailureParser.parse(<String, dynamic>{
        'errors': <String, dynamic>{'email': 'Email is required.'},
      });

      expect(message, 'Email is required.');
    });

    test('returns null for an unrecognised body', () {
      expect(RegisterFailureParser.parse(<String, dynamic>{'a': 1}), isNull);
      expect(RegisterFailureParser.parse('text'), isNull);
      expect(RegisterFailureParser.parse(null), isNull);
    });
  });
}
