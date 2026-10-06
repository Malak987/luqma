/// Validation for the Register form.
///
/// Kept inside the register feature on purpose: adding members to the shared
/// [ValidationErrorKey] would make the exhaustive `switch` in `login_page.dart`
/// a compile error, and Login must not change. The password rules mirror the
/// ASP.NET Identity rules enforced by `POST /api/Account/Register`, so the
/// most common rejection is caught before a round trip.
enum RegisterValidationErrorKey {
  requiredField,
  invalidUsername,
  invalidEmail,
  passwordTooShort,
  passwordMissingUppercase,
  passwordMissingLowercase,
  passwordMissingDigit,
  passwordMissingSymbol,
  passwordMismatch,
  invalidPhoneNumber,
}

abstract final class RegisterValidators {
  static final RegExp _usernamePattern =
      RegExp(r'^[\p{L}\p{N}._-]{3,}$', unicode: true);
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

  static RegisterValidationErrorKey? username(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return RegisterValidationErrorKey.requiredField;
    }
    if (!_usernamePattern.hasMatch(input)) {
      return RegisterValidationErrorKey.invalidUsername;
    }
    return null;
  }

  static RegisterValidationErrorKey? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return RegisterValidationErrorKey.requiredField;
    }
    if (!_emailPattern.hasMatch(input)) {
      return RegisterValidationErrorKey.invalidEmail;
    }
    return null;
  }

  static RegisterValidationErrorKey? phoneNumber(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return RegisterValidationErrorKey.requiredField;
    }
    if (!_phonePattern.hasMatch(input)) {
      return RegisterValidationErrorKey.invalidPhoneNumber;
    }
    return null;
  }

  static RegisterValidationErrorKey? strongPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return RegisterValidationErrorKey.requiredField;
    }
    if (input.length < 6) {
      return RegisterValidationErrorKey.passwordTooShort;
    }
    if (!input.contains(RegExp('[A-Z]'))) {
      return RegisterValidationErrorKey.passwordMissingUppercase;
    }
    if (!input.contains(RegExp('[a-z]'))) {
      return RegisterValidationErrorKey.passwordMissingLowercase;
    }
    if (!input.contains(RegExp('[0-9]'))) {
      return RegisterValidationErrorKey.passwordMissingDigit;
    }
    if (!input.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return RegisterValidationErrorKey.passwordMissingSymbol;
    }
    return null;
  }

  static RegisterValidationErrorKey? confirmPassword(
    String? value,
    String? password,
  ) {
    final input = value ?? '';
    if (input.isEmpty) {
      return RegisterValidationErrorKey.requiredField;
    }
    if (input != password) {
      return RegisterValidationErrorKey.passwordMismatch;
    }
    return null;
  }

  static RegisterValidationErrorKey? requiredText(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return RegisterValidationErrorKey.requiredField;
    }
    return null;
  }
}
