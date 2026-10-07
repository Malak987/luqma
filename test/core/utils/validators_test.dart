import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/utils/password_rules.dart';
import 'package:luqma_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts a normal email', () {
      expect(Validators.email('person@example.test'), isNull);
    });

    test('rejects empty input and plain usernames', () {
      expect(Validators.email('  '), ValidationErrorKey.requiredField);
      expect(Validators.email('new_user'), ValidationErrorKey.invalidEmail);
      expect(Validators.email('a@b'), ValidationErrorKey.invalidEmail);
    });
  });

  group('Validators.strongPassword', () {
    test('reports the first missing rule in order', () {
      expect(Validators.strongPassword(''), ValidationErrorKey.requiredField);
      expect(Validators.strongPassword('Ab1!'),
          ValidationErrorKey.passwordTooShort);
      expect(Validators.strongPassword('abcdef1!'),
          ValidationErrorKey.passwordMissingUppercase);
      expect(Validators.strongPassword('ABCDEF1!'),
          ValidationErrorKey.passwordMissingLowercase);
      expect(Validators.strongPassword('Abcdefg!'),
          ValidationErrorKey.passwordMissingDigit);
      expect(Validators.strongPassword('Abcdef12'),
          ValidationErrorKey.passwordMissingSymbol);
      expect(Validators.strongPassword('Abcde1!'), isNull);
    });
  });

  group('Validators.loginPassword', () {
    test('only checks presence and length', () {
      expect(Validators.loginPassword(''), ValidationErrorKey.requiredField);
      expect(Validators.loginPassword('12345'),
          ValidationErrorKey.passwordTooShort);
      expect(Validators.loginPassword('123456'), isNull);
    });
  });

  group('PasswordRules', () {
    test('tracks every rule independently', () {
      final rules = PasswordRules.of('abc123');
      expect(rules.hasMinLength, isTrue);
      expect(rules.hasLowercase, isTrue);
      expect(rules.hasDigit, isTrue);
      expect(rules.hasUppercase, isFalse);
      expect(rules.hasSymbol, isFalse);
      expect(rules.isStrong, isFalse);
      expect(PasswordRules.of('Abc12!').isStrong, isTrue);
    });
  });
}
