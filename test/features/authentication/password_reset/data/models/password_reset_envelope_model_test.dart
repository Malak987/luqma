import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/authentication/password_reset/data/models/password_reset_envelope_model.dart';

void main() {
  group('PasswordResetEnvelopeModel.fromJson', () {
    test('parses the real ForgotPassword success body whose data is ""', () {
      final envelope = PasswordResetEnvelopeModel.fromJson(<String, dynamic>{
        'message': 'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        'data': '',
        'isSucceeded': true,
        'timestamp': '2026-10-07T07:51:38.8052911Z',
      });

      expect(envelope.isSucceeded, isTrue);
      expect(
        envelope.message,
        'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      );
      expect(envelope.rawData, '');
      expect(envelope.data, isNotNull);
      expect(envelope.data!.carriesToken, isFalse);
    });

    test('parses the real ForgotPassword rejection body whose data is null',
        () {
      final envelope = PasswordResetEnvelopeModel.fromJson(<String, dynamic>{
        'message': 'البريد الإلكتروني غير موجود',
        'data': null,
        'isSucceeded': false,
        'timestamp': '2026-10-07T07:55:01.0000000Z',
      });

      expect(envelope.isSucceeded, isFalse);
      expect(envelope.message, 'البريد الإلكتروني غير موجود');
      expect(envelope.data, isNull,
          reason: 'a rejected call has no usable payload');
      expect(envelope.rawData, isNull);
    });

    test('accepts a null data field on success', () {
      final envelope = PasswordResetEnvelopeModel.fromJson(<String, dynamic>{
        'message': 'ok',
        'data': null,
        'isSucceeded': true,
      });

      expect(envelope.isSucceeded, isTrue);
      expect(envelope.data, isNotNull);
    });

    test('accepts a plain string data field on success', () {
      final envelope = PasswordResetEnvelopeModel.fromJson(<String, dynamic>{
        'message': 'ok',
        'data': 'a string payload',
        'isSucceeded': true,
      });

      expect(envelope.rawData, 'a string payload');
      expect(envelope.data, isNotNull);
    });

    test('accepts an object data field on success', () {
      final envelope = PasswordResetEnvelopeModel.fromJson(<String, dynamic>{
        'message': 'ok',
        'data': <String, dynamic>{'userId': 7},
        'isSucceeded': true,
      });

      expect(envelope.rawData, <String, dynamic>{'userId': 7});
      expect(envelope.data, isNotNull);
    });

    test('reads a map with non-String static type', () {
      // Dio can hand back a `Map<dynamic, dynamic>` depending on the decoder.
      final envelope = PasswordResetEnvelopeModel.fromJson(<Object?, Object?>{
        'message': 'ok',
        'data': '',
        'isSucceeded': true,
      });

      expect(envelope.isSucceeded, isTrue);
      expect(envelope.message, 'ok');
    });

    test('keeps the message when it is blank as null', () {
      final envelope = PasswordResetEnvelopeModel.fromJson(<String, dynamic>{
        'message': '   ',
        'data': null,
        'isSucceeded': false,
      });

      expect(envelope.message, isNull);
    });

    test('rejects a body without the isSucceeded flag', () {
      expect(
        () => PasswordResetEnvelopeModel.fromJson(<String, dynamic>{
          'message': 'ok',
          'data': '',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-map body', () {
      expect(
        () => PasswordResetEnvelopeModel.fromJson('a bare string'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PasswordResetEnvelopeModel.fromJson(null),
        throwsA(isA<FormatException>()),
      );
    });

    test('reports a success payload carrying no message as malformed', () {
      expect(
        () => PasswordResetEnvelopeModel.fromJson(<String, dynamic>{
          'data': null,
          'isSucceeded': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
