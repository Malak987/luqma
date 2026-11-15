import '../utils/validators.dart';
import 'app_localizations.dart';

/// Maps a [ValidationErrorKey] to localized copy in exactly one place, so
/// pages no longer carry their own copy of the same `switch`.
extension ValidationMessages on AppLocalizations {
  String? validationMessage(ValidationErrorKey? error) {
    switch (error) {
      case ValidationErrorKey.requiredField:
        return common.validationRequired;
      case ValidationErrorKey.invalidUsername:
        return auth.validationUsername;
      case ValidationErrorKey.invalidEmail:
        return auth.validationEmail;
      case ValidationErrorKey.invalidPhoneNumber:
        return auth.validationPhoneNumber;
      case ValidationErrorKey.passwordTooShort:
        return common.validationPasswordLength;
      case ValidationErrorKey.passwordMissingUppercase:
        return auth.validationPasswordUppercase;
      case ValidationErrorKey.passwordMissingLowercase:
        return auth.validationPasswordLowercase;
      case ValidationErrorKey.passwordMissingDigit:
        return auth.validationPasswordDigit;
      case ValidationErrorKey.passwordMissingSymbol:
        return auth.validationPasswordSymbol;
      case ValidationErrorKey.passwordMismatch:
        return auth.validationPasswordMismatch;
      case ValidationErrorKey.otpInvalid:
        return auth.validationOtpFormat;
      case null:
        return null;
    }
  }
}
