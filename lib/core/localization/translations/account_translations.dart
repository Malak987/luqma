import 'package:flutter/widgets.dart';

/// Copy of the Account tab: preferences and signing out.
class AccountTranslations {
  AccountTranslations(this.locale);

  final Locale locale;

  bool get _isArabic => locale.languageCode == 'ar';

  String get title => _isArabic ? 'حسابي' : 'My account';
  String get profileSubtitle => _isArabic
      ? 'إدارة حسابك ومظهر التطبيق من مكان واحد.'
      : 'Manage your account and appearance from one place.';
  String get overview => _isArabic ? 'نظرة على الحساب' : 'Account overview';
  String get accountSection => _isArabic ? 'الحساب' : 'Account';
  String get editProfile => _isArabic ? 'تعديل الملف الشخصي' : 'Edit profile';
  String get changePassword =>
      _isArabic ? 'تغيير كلمة المرور' : 'Change password';
  String get phone => _isArabic ? 'الهاتف' : 'Phone';
  String get address => _isArabic ? 'العنوان' : 'Address';
  String get unavailable =>
      _isArabic ? 'غير متاح حاليًا' : 'Currently unavailable';
  String get appearance =>
      _isArabic ? 'المظهر واللغة' : 'Appearance & language';
  String get preferences => _isArabic ? 'التفضيلات' : 'Preferences';
  String get languageSubtitle => _isArabic
      ? 'بدّل بين العربية والإنجليزية'
      : 'Switch between Arabic and English';

  String get logout => _isArabic ? 'تسجيل الخروج' : 'Log out';
  String get logoutConfirmTitle => _isArabic ? 'تسجيل الخروج؟' : 'Log out?';
  String get logoutConfirmMessage => _isArabic
      ? 'ستحتاج إلى تسجيل الدخول مرة أخرى من أجل المتابعة.'
      : 'You will need to sign in again to continue.';
}
