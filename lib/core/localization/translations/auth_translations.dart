import 'package:flutter/widgets.dart';

/// Authentication copy grouped by feature so the catalog can grow without
/// spreading string literals through widgets.
class AuthTranslations {
  AuthTranslations(this.locale);

  final Locale locale;

  bool get _isArabic => locale.languageCode == 'ar';

  String get emailOrUsername => _isArabic ? 'اسم المستخدم أو البريد' : 'Username or email';
  String get usernameOrEmailLabel => _isArabic ? 'اسم المستخدم أو البريد' : 'Username or email';
  String get password => _isArabic ? 'كلمة المرور' : 'Password';
  String get login => _isArabic ? 'تسجيل الدخول' : 'Login';
  String get forgotPassword => _isArabic ? 'هل نسيت كلمة المرور؟' : 'Forgot password?';
  String get continueWith => _isArabic ? 'أو المتابعة عبر' : 'Or continue with';
  String get dontHaveAccount => _isArabic ? 'ليس لديك حساب؟' : "Don't have an account?";
  String get registerNow => _isArabic ? 'سجل الآن' : 'Register now';
  String get showPassword => _isArabic ? 'إظهار كلمة المرور' : 'Show password';
  String get hidePassword => _isArabic ? 'إخفاء كلمة المرور' : 'Hide password';
  String get loginSuccess => _isArabic ? 'تم تسجيل الدخول بنجاح' : 'Signed in successfully';
  String get loginFailed => _isArabic ? 'تعذر تسجيل الدخول' : 'Unable to sign in';
  String get networkError => _isArabic ? 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى' : 'Check your internet connection and try again';
  String get invalidCredentials => _isArabic ? 'بيانات الدخول غير صحيحة' : 'The username or password is incorrect';
  String get unknownError => _isArabic ? 'حدث خطأ غير متوقع. حاول مرة أخرى' : 'Something went wrong. Please try again';
  String get loginLoading => _isArabic ? 'جارٍ تسجيل الدخول' : 'Signing in';
  String get apple => _isArabic ? 'آبل' : 'Apple';
  String get facebook => _isArabic ? 'فيسبوك' : 'Facebook';
  String get google => _isArabic ? 'جوجل' : 'Google';
  String get appleLogin => _isArabic ? 'المتابعة باستخدام آبل' : 'Continue with Apple';
  String get facebookLogin => _isArabic ? 'المتابعة باستخدام فيسبوك' : 'Continue with Facebook';
  String get googleLogin => _isArabic ? 'المتابعة باستخدام جوجل' : 'Continue with Google';
  String get loginFormLabel => _isArabic ? 'نموذج تسجيل الدخول' : 'Login form';
}
