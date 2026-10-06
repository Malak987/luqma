enum ValidationErrorKey {
  requiredField,
  invalidUsernameOrEmail,
  passwordTooShort,
}

abstract final class Validators {
  static ValidationErrorKey? usernameOrEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }

    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input);
    final isUsername = RegExp(r'^[\p{L}\p{N}._-]{3,}$', unicode: true)
        .hasMatch(input);
    if (!isEmail && !isUsername) {
      return ValidationErrorKey.invalidUsernameOrEmail;
    }

    return null;
  }

  static ValidationErrorKey? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return ValidationErrorKey.requiredField;
    }
    if (input.length < 6) {
      return ValidationErrorKey.passwordTooShort;
    }
    return null;
  }
}
