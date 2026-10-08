import 'package:flutter/widgets.dart';

class CommonTranslations {
  CommonTranslations(this.locale);

  final Locale locale;

  bool get _isArabic => locale.languageCode == 'ar';

  String get brandName => _isArabic ? 'لقمة' : 'Luqma';
  String get appName => 'Luqma Culinary';
  String get register => _isArabic ? 'إنشاء حساب' : 'Create account';
  String get forgotPassword =>
      _isArabic ? 'استعادة كلمة المرور' : 'Forgot password';
  String get resetPassword =>
      _isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset password';
  String get verification => _isArabic ? 'التحقق' : 'Verification';
  String get home => _isArabic ? 'الرئيسية' : 'Home';
  String get comingSoon =>
      _isArabic ? 'هذه الصفحة قادمة قريبًا' : 'This page is coming soon';
  String get back => _isArabic ? 'رجوع' : 'Back';
  String get cancel => _isArabic ? 'إلغاء' : 'Cancel';
  String get validationRequired =>
      _isArabic ? 'هذا الحقل مطلوب' : 'This field is required';
  String get validationPasswordLength => _isArabic
      ? 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل'
      : 'Password must be at least 6 characters';
}
