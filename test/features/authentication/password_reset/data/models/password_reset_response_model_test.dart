import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/authentication/password_reset/data/models/password_reset_response_model.dart';

void main() {
  group('PasswordResetResponseModel.fromEnvelope', () {
    test('keeps the envelope message and the empty-string payload', () {
      // The real ForgotPassword success body has `data: ""`.
      final model = PasswordResetResponseModel.fromEnvelope(
        data: '',
        message: 'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      );

      expect(
        model.message,
        'تم إرسال رمز إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      );
      expect(model.payload, '');
      expect(model.carriesToken, isFalse,
          reason: 'an empty data string is not a token');
    });

    test('treats a null payload as no data', () {
      final model =
          PasswordResetResponseModel.fromEnvelope(data: null, message: 'ok');

      expect(model.payload, isNull);
      expect(model.carriesToken, isFalse);
    });

    test('prefers the envelope message over a string payload', () {
      final model = PasswordResetResponseModel.fromEnvelope(
        data: 'payload text',
        message: 'envelope text',
      );

      expect(model.message, 'envelope text');
    });

    test('falls back to a string payload when the message is missing', () {
      final model =
          PasswordResetResponseModel.fromEnvelope(data: 'payload text');

      expect(model.message, 'payload text');
    });

    test('trims the message', () {
      final model = PasswordResetResponseModel.fromEnvelope(
        data: null,
        message: '  spaced  ',
      );

      expect(model.message, 'spaced');
    });

    test('rejects a payload with no usable message', () {
      expect(
        () => PasswordResetResponseModel.fromEnvelope(data: null),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PasswordResetResponseModel.fromEnvelope(data: '   ', message: ''),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PasswordResetResponseModel.fromEnvelope(
          data: <String, dynamic>{'token': 'abc'},
        ),
        throwsA(isA<FormatException>()),
        reason: 'an object payload with no message must not become an empty '
            'confirmation',
      );
    });

    test('reports a token only for an object payload carrying one', () {
      final withToken = PasswordResetResponseModel.fromEnvelope(
        data: <String, dynamic>{'token': 'abc'},
        message: 'ok',
      );
      expect(withToken.carriesToken, isTrue);

      final blankToken = PasswordResetResponseModel.fromEnvelope(
        data: <String, dynamic>{'token': '  '},
        message: 'ok',
      );
      expect(blankToken.carriesToken, isFalse);

      final otherObject = PasswordResetResponseModel.fromEnvelope(
        data: <String, dynamic>{'userId': 7},
        message: 'ok',
      );
      expect(otherObject.carriesToken, isFalse);

      final stringPayload = PasswordResetResponseModel.fromEnvelope(
        data: 'a plain string',
        message: 'ok',
      );
      expect(stringPayload.carriesToken, isFalse,
          reason: 'only an explicit token field counts as credentials');
    });
  });
}
