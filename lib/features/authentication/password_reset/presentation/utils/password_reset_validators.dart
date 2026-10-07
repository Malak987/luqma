/// Validation for the password-reset screens.
///
/// Kept inside this feature on purpose: adding members to the shared
/// [ValidationErrorKey] would make the exhaustive `switch` in `login_page.dart`
/// a compile error, and Login must not change.
///
/// The password rules below mirror the ones Register enforces, which in turn
/// mirror the ASP.NET Identity rules this backend applies. They are a **courtesy
/// only** — the exact rules for `ResetPassword` are not verified, the server
/// stays authoritative, and its Arabic message is what the user ultimately sees.
enum PasswordResetValidationErrorKey {
  requiredField,
  invalidEmail,
  otpInvalid,
  passwordTooShort,
  passwordMissingUppercase,
  passwordMissingLowercase,
  passwordMissingDigit,
  passwordMissingSymbol,
  passwordMismatch,
}

abstract final class PasswordResetValidators {
  /// The OTP length is **unverified** on this endpoint. Six digits matches the
  /// email-verification screen; if the backend issues a different length the
  /// server remains authoritative and its message is shown.
  static const int otpLength = 6;

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _otpPattern = RegExp('^[0-9]{$otpLength}\$');

  static PasswordResetValidationErrorKey? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return PasswordResetValidationErrorKey.requiredField;
    }
    if (!_emailPattern.hasMatch(input)) {
      return PasswordResetValidationErrorKey.invalidEmail;
    }
    return null;
  }

  static PasswordResetValidationErrorKey? otp(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return PasswordResetValidationErrorKey.requiredField;
    }
    if (!_otpPattern.hasMatch(input)) {
      return PasswordResetValidationErrorKey.otpInvalid;
    }
    return null;
  }

  static PasswordResetValidationErrorKey? newPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return PasswordResetValidationErrorKey.requiredField;
    }
    if (input.length < 6) {
      return PasswordResetValidationErrorKey.passwordTooShort;
    }
    if (!input.contains(RegExp('[A-Z]'))) {
      return PasswordResetValidationErrorKey.passwordMissingUppercase;
    }
    if (!input.contains(RegExp('[a-z]'))) {
      return PasswordResetValidationErrorKey.passwordMissingLowercase;
    }
    if (!input.contains(RegExp('[0-9]'))) {
      return PasswordResetValidationErrorKey.passwordMissingDigit;
    }
    if (!input.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return PasswordResetValidationErrorKey.passwordMissingSymbol;
    }
    return null;
  }

  static PasswordResetValidationErrorKey? confirmPassword(
    String? value,
    String? newPassword,
  ) {
    final input = value ?? '';
    if (input.isEmpty) {
      return PasswordResetValidationErrorKey.requiredField;
    }
    if (input != newPassword) {
      return PasswordResetValidationErrorKey.passwordMismatch;
    }
    return null;
  }
}
