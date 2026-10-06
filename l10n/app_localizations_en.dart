// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get brandName => 'Luqma';

  @override
  String get brandTagline => 'LUQMA CULINARY';

  @override
  String get register => 'Create account';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get verification => 'Verification';

  @override
  String get home => 'Home';

  @override
  String get comingSoon => 'This page is coming soon';

  @override
  String get back => 'Back';

  @override
  String get emailOrUsername => 'Username or email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get continueWith => 'Or continue with';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register now';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get loginSuccess => 'Signed in successfully';

  @override
  String get loginFailed => 'Unable to sign in';

  @override
  String get networkError => 'Check your internet connection and try again';

  @override
  String get invalidCredentials => 'The username or password is incorrect';

  @override
  String get unknownError => 'Something went wrong. Please try again';

  @override
  String get loginLoading => 'Signing in';

  @override
  String get appleLogin => 'Continue with Apple';

  @override
  String get facebookLogin => 'Continue with Facebook';

  @override
  String get googleLogin => 'Continue with Google';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationUsernameOrEmail => 'Enter a valid email or username';

  @override
  String get validationPasswordLength =>
      'Password must be at least 6 characters';
}
