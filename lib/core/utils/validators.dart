import 'password_rules.dart';

/// Every client-side validation outcome in the app. One enum + one mapper
/// (see `validation_messages.dart`) replaces the three per-feature copies.
enum ValidationErrorKey {
  requiredField,
  invalidUsername,
  invalidEmail,
  invalidPhoneNumber,
  passwordTooShort,
  passwordMissingUppercase,
  passwordMissingLowercase,
  passwordMissingDigit,
  passwordMissingSymbol,
  passwordMismatch,
  otpInvalid,
}

abstract final class Validators {
  /// Six digits, matching the verification and password-reset screens. The
  /// server stays authoritative if it ever issues a different length.
  static const int otpLength = 6;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _usernamePattern =
      RegExp(r'^[\p{L}\p{N}._-]{3,}$', unicode: true);
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');
  static final RegExp _otpPattern = RegExp('^[0-9]{$otpLength}\$');

  static ValidationErrorKey? requiredText(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    return null;
  }

  static ValidationErrorKey? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    if (!_emailPattern.hasMatch(input)) {
      return ValidationErrorKey.invalidEmail;
    }
    return null;
  }

  static ValidationErrorKey? username(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    if (!_usernamePattern.hasMatch(input)) {
      return ValidationErrorKey.invalidUsername;
    }
    return null;
  }

  static ValidationErrorKey? phoneNumber(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    if (!_phonePattern.hasMatch(input)) {
      return ValidationErrorKey.invalidPhoneNumber;
    }
    return null;
  }

  /// Login only checks presence and length: an existing account may predate
  /// the current strength policy, so the server decides everything else.
  static ValidationErrorKey? loginPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    if (input.length < PasswordRules.minLength) {
      return ValidationErrorKey.passwordTooShort;
    }
    return null;
  }

  /// Used when *choosing* a password (register, reset).
  static ValidationErrorKey? strongPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    final rules = PasswordRules.of(input);
    if (!rules.hasMinLength) {
      return ValidationErrorKey.passwordTooShort;
    }
    if (!rules.hasUppercase) {
      return ValidationErrorKey.passwordMissingUppercase;
    }
    if (!rules.hasLowercase) {
      return ValidationErrorKey.passwordMissingLowercase;
    }
    if (!rules.hasDigit) {
      return ValidationErrorKey.passwordMissingDigit;
    }
    if (!rules.hasSymbol) {
      return ValidationErrorKey.passwordMissingSymbol;
    }
    return null;
  }

  static ValidationErrorKey? confirmPassword(String? value, String? password) {
    final input = value ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    if (input != password) {
      return ValidationErrorKey.passwordMismatch;
    }
    return null;
  }

  static ValidationErrorKey? otp(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    if (!_otpPattern.hasMatch(input)) {
      return ValidationErrorKey.otpInvalid;
    }
    return null;
  }
}
