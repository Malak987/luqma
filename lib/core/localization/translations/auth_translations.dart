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

  // ------------------------------------------------------------
  // Register
  // ------------------------------------------------------------
  String get registerFormLabel => _isArabic ? 'نموذج إنشاء الحساب' : 'Create account form';
  String get userName => _isArabic ? 'اسم المستخدم' : 'Username';
  String get userNameLabel => _isArabic ? 'اسم المستخدم' : 'Username';
  String get email => _isArabic ? 'البريد الإلكتروني' : 'Email';
  String get emailLabel => _isArabic ? 'البريد الإلكتروني' : 'Email';
  String get phoneNumber => _isArabic ? 'رقم الهاتف' : 'Phone number';
  String get phoneNumberLabel => _isArabic ? 'رقم الهاتف' : 'Phone number';
  String get address => _isArabic ? 'العنوان' : 'Address';
  String get addressLabel => _isArabic ? 'العنوان' : 'Address';
  String get confirmPassword => _isArabic ? 'تأكيد كلمة المرور' : 'Confirm password';
  String get confirmPasswordLabel => _isArabic ? 'تأكيد كلمة المرور' : 'Confirm password';
  String get createAccount => _isArabic ? 'إنشاء الحساب' : 'Create account';
  String get registerLoading => _isArabic ? 'جارٍ إنشاء الحساب' : 'Creating account';
  String get registerFailed => _isArabic ? 'تعذر إنشاء الحساب' : 'Unable to create the account';
  String get haveAccount => _isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?';
  String get loginNow => _isArabic ? 'سجّل الدخول' : 'Sign in';
  String get backToLogin => _isArabic ? 'العودة إلى تسجيل الدخول' : 'Back to sign in';

  // Client-side validation, mirroring the backend registration rules.
  String get validationUsername => _isArabic
      ? 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل'
      : 'Username must be at least 3 characters';
  String get validationEmail => _isArabic
      ? 'أدخل بريدًا إلكترونيًا صحيحًا'
      : 'Enter a valid email address';
  String get validationPasswordUppercase => _isArabic
      ? 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل'
      : 'Password must contain at least one uppercase letter';
  String get validationPasswordLowercase => _isArabic
      ? 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل'
      : 'Password must contain at least one lowercase letter';
  String get validationPasswordDigit => _isArabic
      ? 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل'
      : 'Password must contain at least one number';
  String get validationPasswordSymbol => _isArabic
      ? 'كلمة المرور يجب أن تحتوي على رمز واحد على الأقل'
      : 'Password must contain at least one symbol';
  String get validationPasswordMismatch => _isArabic
      ? 'كلمتا المرور غير متطابقتين'
      : 'The two passwords do not match';
  String get validationPhoneNumber => _isArabic
      ? 'أدخل رقم هاتف صحيحًا'
      : 'Enter a valid phone number';
}
