import 'package:flutter/widgets.dart';

/// Home-screen copy, kept beside the auth catalog so the app keeps one
/// `AppLocalizations` entry point while each feature owns its own strings.
class HomeTranslations {
  HomeTranslations(this.locale);

  final Locale locale;

  bool get _isArabic => locale.languageCode == 'ar';

  /// Greets the signed-in user and falls back to a name-less greeting when the
  /// stored session has no display name to show.
  String greeting(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) {
      return _isArabic ? 'أهلاً بعودتك' : 'Welcome back';
    }
    return _isArabic ? 'أهلاً بعودتك، $trimmed' : 'Welcome back, $trimmed';
  }

  String get searchHint =>
      _isArabic ? 'ابحث عن طبق أو مطعم' : 'Search for a dish or a restaurant';

  /// Shown when the search entry point is used before the search API exists.
  String get searchUnavailable =>
      _isArabic ? 'البحث سيتوفر قريبًا' : 'Search will be available soon';

  String get categoriesTitle => _isArabic ? 'الأقسام' : 'Categories';

  /// Empty state of the catalog section until the catalog API is connected.
  String get categoriesEmpty => _isArabic
      ? 'ستظهر الأقسام هنا قريبًا'
      : 'Categories will appear here soon';

  String get restaurantsTitle => _isArabic ? 'المطاعم' : 'Restaurants';

  /// Empty state of the restaurants section until that API is connected.
  String get restaurantsEmpty => _isArabic
      ? 'ستظهر المطاعم هنا قريبًا'
      : 'Restaurants will appear here soon';

  String get logout => _isArabic ? 'تسجيل الخروج' : 'Log out';
  String get logoutConfirmTitle => _isArabic ? 'تسجيل الخروج؟' : 'Log out?';
  String get logoutConfirmMessage => _isArabic
      ? 'ستحتاج إلى تسجيل الدخول مرة أخرى من أجل المتابعة.'
      : 'You will need to sign in again to continue.';

  /// Failure copy of [HomeStatus.failure]; shown when the screen's data could
  /// not be read at all.
  String get loadFailed => _isArabic
      ? 'تعذر تحميل الصفحة الرئيسية'
      : "We couldn't load your home screen";

  String get retry => _isArabic ? 'حاول مرة أخرى' : 'Try again';
}
