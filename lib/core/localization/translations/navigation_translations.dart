import 'package:flutter/widgets.dart';

/// Labels of the persistent bottom navigation bar and its placeholder tabs.
class NavigationTranslations {
  NavigationTranslations(this.locale);

  final Locale locale;

  bool get _isArabic => locale.languageCode == 'ar';

  String get home => _isArabic ? 'الرئيسية' : 'Home';
  String get restaurants => _isArabic ? 'المطاعم' : 'Restaurants';
  String get cart => _isArabic ? 'السلة' : 'Cart';
  String get favorites => _isArabic ? 'المفضلة' : 'Favourites';
  String get account => _isArabic ? 'حسابي' : 'Account';
}
