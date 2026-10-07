/// Single source of truth for the password policy.
///
/// The rules mirror the ASP.NET Identity rules enforced by the backend. Both
/// the validators and the live checklist under the password field read from
/// here, so what the user sees ticked is exactly what gets validated.
class PasswordRules {
  const PasswordRules._(this._value);

  factory PasswordRules.of(String? value) => PasswordRules._(value ?? '');

  static const int minLength = 6;

  static final RegExp _upper = RegExp('[A-Z]');
  static final RegExp _lower = RegExp('[a-z]');
  static final RegExp _digit = RegExp('[0-9]');
  static final RegExp _symbol = RegExp(r'[^A-Za-z0-9]');

  final String _value;

  bool get hasMinLength => _value.length >= minLength;
  bool get hasUppercase => _upper.hasMatch(_value);
  bool get hasLowercase => _lower.hasMatch(_value);
  bool get hasDigit => _digit.hasMatch(_value);
  bool get hasSymbol => _symbol.hasMatch(_value);

  bool get isStrong =>
      hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSymbol;
}
