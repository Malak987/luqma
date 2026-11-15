import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/confirm_email_request_model.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/email_verification_envelope_model.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/email_verification_failure_parser.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/email_verification_response_model.dart';
import 'package:luqma_app/features/authentication/email_verification/data/models/resend_otp_request_model.dart';

void main() {
  group('ConfirmEmailRequestModel', () {
    test('serializes exactly the two contract fields', () {
      const request = ConfirmEmailRequestModel(
        email: 'person@example.test',
        otp: '482913',
      );

      expect(
        request.toJson(),
        <String, dynamic>{
          'email': 'person@example.test',
          'otp': '482913',
        },
      );
    });

    test('keeps the OTP verbatim and never adds a token or userId', () {
      const request = ConfirmEmailRequestModel(
        email: 'person@example.test',
        otp: ' 482913 ',
      );
      final json = request.toJson();

      expect(json['otp'], ' 482913 ');
      expect(json.containsKey('token'), isFalse);
      expect(json.containsKey('userId'), isFalse);
      expect(json.keys, hasLength(2));
    });
  });

  group('ResendOtpRequestModel', () {
    test('serializes only the email', () {
      const request = ResendOtpRequestModel(email: 'person@example.test');

      expect(
          request.toJson(), <String, dynamic>{'email': 'person@example.test'});
    });
  });

  group('EmailVerificationEnvelopeModel', () {
    test('parses the ResendOtp success envelope whose data is an empty string',
        () {
      final envelope = EmailVerificationEnvelopeModel.fromJson(
        <String, dynamic>{
          'message': 'تم إعادة إرسال رمز التحقق بنجاح',
          'data': '',
          'isSucceeded': true,
          'timestamp': '2026-10-06T20:54:42.7743688Z',
        },
      );

      expect(envelope.isSucceeded, isTrue);
      expect(envelope.rawData, '');
      expect(envelope.data?.message, 'تم إعادة إرسال رمز التحقق بنجاح');
    });

    test('parses a Luqma failure envelope and keeps the Arabic message', () {
      final envelope = EmailVerificationEnvelopeModel.fromJson(
        <String, dynamic>{
          'message': 'رمز التحقق غير صحيح أو منتهي الصلاحية',
          'data': null,
          'isSucceeded': false,
          'timestamp': '2026-10-06T20:54:12.9592851Z',
        },
      );

      expect(envelope.isSucceeded, isFalse);
      expect(envelope.message, 'رمز التحقق غير صحيح أو منتهي الصلاحية');
      expect(envelope.data, isNull);
      expect(envelope.rawData, isNull);
    });

    test('tolerates a string data payload with no envelope message', () {
      final envelope = EmailVerificationEnvelopeModel.fromJson(
        <String, dynamic>{
          'data': 'تم التأكيد بنجاح',
          'isSucceeded': true,
        },
      );

      expect(envelope.data?.message, 'تم التأكيد بنجاح');
    });

    test('tolerates an object data payload (future contract drift)', () {
      final envelope = EmailVerificationEnvelopeModel.fromJson(
        <String, dynamic>{
          'message': 'تم التأكيد بنجاح',
          'data': <String, dynamic>{'token': 'a-token'},
          'isSucceeded': true,
        },
      );

      expect(envelope.data?.message, 'تم التأكيد بنجاح');
      expect(envelope.data?.carriesToken, isTrue);
    });

    test('accepts a map whose keys are not statically String-typed', () {
      final envelope =
          EmailVerificationEnvelopeModel.fromJson(<Object?, Object?>{
        'message': 'ok',
        'data': '',
        'isSucceeded': true,
      });

      expect(envelope.isSucceeded, isTrue);
    });

    test('rejects an envelope without a boolean isSucceeded', () {
      expect(
        () => EmailVerificationEnvelopeModel.fromJson(<String, dynamic>{
          'isSucceeded': 'true',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a payload that is not a map', () {
      expect(
        () => EmailVerificationEnvelopeModel.fromJson('not-an-envelope'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a success envelope that carries no usable message', () {
      expect(
        () => EmailVerificationEnvelopeModel.fromJson(<String, dynamic>{
          'isSucceeded': true,
          'data': <String, dynamic>{'unrelated': 1},
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('EmailVerificationResponseModel', () {
    test('prefers the envelope message over the data payload', () {
      final model = EmailVerificationResponseModel.fromEnvelope(
        data: 'data text',
        message: 'envelope text',
      );

      expect(model.message, 'envelope text');
    });

    test('falls back to a non-empty string data payload', () {
      final model = EmailVerificationResponseModel.fromEnvelope(
        data: 'data text',
        message: null,
      );

      expect(model.message, 'data text');
    });

    test('reports no token for the shapes actually observed', () {
      expect(
        EmailVerificationResponseModel.fromEnvelope(data: '', message: 'ok')
            .carriesToken,
        isFalse,
      );
      expect(
        EmailVerificationResponseModel.fromEnvelope(data: null, message: 'ok')
            .carriesToken,
        isFalse,
      );
    });

    test('detects a token only if a future payload supplies one', () {
      final model = EmailVerificationResponseModel.fromEnvelope(
        data: <String, dynamic>{'token': '   '},
        message: 'ok',
      );

      expect(model.carriesToken, isFalse);
    });
  });

  group('EmailVerificationFailureParser', () {
    test('reads the message from a failed Luqma envelope', () {
      expect(
        EmailVerificationFailureParser.parse(<String, dynamic>{
          'message': 'المستخدم غير موجود',
          'data': null,
          'isSucceeded': false,
        }),
        'المستخدم غير موجود',
      );
    });

    test('ignores a successful envelope', () {
      expect(
        EmailVerificationFailureParser.parse(<String, dynamic>{
          'message': 'all good',
          'isSucceeded': true,
        }),
        isNull,
      );
    });

    test('parses dotted/positional ProblemDetails keys ("\$.otp", "request")',
        () {
      final message = EmailVerificationFailureParser.parse(<String, dynamic>{
        'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'errors': <String, dynamic>{
          'request': <String>['The request field is required.'],
          r'$.otp': <String>[
            'The JSON value could not be converted to System.String.',
          ],
        },
        'traceId': '00-trace',
      });

      expect(message, contains('One or more validation errors occurred.'));
      expect(message, contains('The request field is required.'));
      expect(message, contains('System.String'));
    });

    test('parses PascalCase ProblemDetails keys ("Otp")', () {
      expect(
        EmailVerificationFailureParser.parse(<String, dynamic>{
          'errors': <String, dynamic>{
            'Otp': <String>['The Otp field is required.'],
          },
          'traceId': '00-trace',
        }),
        'The Otp field is required.',
      );
    });

    test('handles an errors map whose values are plain strings', () {
      expect(
        EmailVerificationFailureParser.parse(<String, dynamic>{
          'errors': <String, dynamic>{'email': 'Email is required.'},
        }),
        'Email is required.',
      );
    });

    test('returns null for an unrecognised body', () {
      expect(
        EmailVerificationFailureParser.parse(<String, dynamic>{'a': 1}),
        isNull,
      );
      expect(EmailVerificationFailureParser.parse('text'), isNull);
      expect(EmailVerificationFailureParser.parse(null), isNull);
    });
  });
}
