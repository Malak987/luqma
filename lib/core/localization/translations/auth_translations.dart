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

  // ------------------------------------------------------------
  // Email verification
  // ------------------------------------------------------------
  String get verifyEmailTitle => _isArabic ? 'تأكيد البريد الإلكتروني' : 'Confirm your email';
  String get verificationFormLabel => _isArabic ? 'نموذج تأكيد البريد الإلكتروني' : 'Email confirmation form';
  String get otp => _isArabic ? 'رمز التحقق' : 'Verification code';
  String get otpLabel => _isArabic ? 'رمز التحقق' : 'Verification code';
  String get confirm => _isArabic ? 'تأكيد' : 'Confirm';
  String get confirmLoading => _isArabic ? 'جارٍ التأكيد' : 'Confirming';
  String get verificationSuccess => _isArabic ? 'تم تأكيد البريد الإلكتروني بنجاح' : 'Email confirmed successfully';
  String get verificationFailed => _isArabic ? 'تعذر تأكيد البريد الإلكتروني' : 'Unable to confirm the email';
  String get resendOtp => _isArabic ? 'إعادة إرسال الرمز' : 'Resend code';
  String get resendOtpLoading => _isArabic ? 'جارٍ إرسال الرمز' : 'Sending code';
  String get resendOtpFailed => _isArabic ? 'تعذر إعادة إرسال الرمز' : 'Unable to resend the code';
  String get didNotReceiveCode => _isArabic ? 'لم يصلك الرمز؟' : "Didn't receive the code?";
  String get sentCodeTo => _isArabic ? 'أرسلنا رمز التحقق إلى' : 'We sent a verification code to';
  String get verificationEmailLabel => _isArabic ? 'البريد الإلكتروني' : 'Email';
  String get validationOtpRequired => _isArabic ? 'أدخل رمز التحقق' : 'Enter the verification code';
  String get validationOtpLength => _isArabic
      ? 'رمز التحقق يجب أن يكون 6 أرقام'
      : 'The verification code must be 6 digits';
  String get backToLoginFromVerification => _isArabic ? 'العودة إلى تسجيل الدخول' : 'Back to sign in';

  /// `seconds` is the remaining cooldown before another code can be requested.
  String resendIn(int seconds) => _isArabic
      ? 'إعادة الإرسال بعد $seconds ثانية'
      : 'Resend available in ${seconds}s';

  // ------------------------------------------------------------
  // Password reset
  // ------------------------------------------------------------
  String get forgotPasswordTitle => _isArabic ? 'استعادة كلمة المرور' : 'Reset your password';
  String get forgotPasswordSubtitle => _isArabic
      ? 'أدخل بريدك الإلكتروني وسنرسل لك رمز إعادة التعيين'
      : 'Enter your email and we will send you a reset code';
  String get forgotPasswordFormLabel => _isArabic ? 'نموذج استعادة كلمة المرور' : 'Password reset form';
  String get sendResetCode => _isArabic ? 'إرسال الرمز' : 'Send reset code';
  String get sendResetCodeLoading => _isArabic ? 'جارٍ إرسال الرمز' : 'Sending code';
  String get forgotPasswordFailed => _isArabic ? 'تعذر إرسال رمز إعادة التعيين' : 'Unable to send the reset code';

  String get resetPasswordTitle => _isArabic ? 'إعادة تعيين كلمة المرور' : 'Choose a new password';
  String get resetPasswordFormLabel => _isArabic ? 'نموذج إعادة تعيين كلمة المرور' : 'New password form';
  String get resetCodeSentTo => _isArabic ? 'أرسلنا رمز إعادة التعيين إلى' : 'We sent a reset code to';
  String get resetOtp => _isArabic ? 'رمز إعادة التعيين' : 'Reset code';
  String get resetOtpLabel => _isArabic ? 'رمز إعادة التعيين' : 'Reset code';
  String get newPassword => _isArabic ? 'كلمة المرور الجديدة' : 'New password';
  String get newPasswordLabel => _isArabic ? 'كلمة المرور الجديدة' : 'New password';
  String get confirmNewPassword => _isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm new password';
  String get confirmNewPasswordLabel => _isArabic ? 'تأكيد كلمة المرور الجديدة' : 'Confirm new password';
  String get resetPasswordAction => _isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset password';
  String get resetPasswordLoading => _isArabic ? 'جارٍ إعادة التعيين' : 'Resetting password';
  String get resetPasswordSuccess => _isArabic
      ? 'تم تغيير كلمة المرور بنجاح'
      : 'Your password has been changed';
  String get resetPasswordFailed => _isArabic ? 'تعذر إعادة تعيين كلمة المرور' : 'Unable to reset the password';
  String get resendResetCode => _isArabic ? 'إعادة إرسال الرمز' : 'Resend code';
  String get didNotReceiveResetCode => _isArabic ? 'لم يصلك الرمز؟' : "Didn't receive the code?";
  String get backToLoginFromReset => _isArabic ? 'العودة إلى تسجيل الدخول' : 'Back to sign in';

  // Reuses the shared `validationEmail` / `validationPassword*` copy above;
  // only the reset-specific wording is new.
  String get validationOtpFormat => _isArabic
      ? 'رمز إعادة التعيين يجب أن يكون 6 أرقام'
      : 'The reset code must be 6 digits';
  String get validationNewPasswordLength => _isArabic
      ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
      : 'Password must be at least 6 characters';
  String get validationNewPasswordMismatch => _isArabic
      ? 'كلمتا المرور غير متطابقتين'
      : 'The two passwords do not match';
}
