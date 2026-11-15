import 'package:flutter/widgets.dart';

/// Copy of the Account tab: preferences and signing out.
class AccountTranslations {
  AccountTranslations(this.locale);

  final Locale locale;

  bool get _isArabic => locale.languageCode == 'ar';

  String get title => _isArabic ? 'حسابي' : 'My account';
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
