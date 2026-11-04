import 'package:flutter/widgets.dart';

/// Onboarding copy catalog supporting Arabic and English.
class OnboardingTranslations {
  OnboardingTranslations(this.locale);

  final Locale locale;

  bool get _isArabic => locale.languageCode == 'ar';

  String get skip => _isArabic ? 'تخطي' : 'Skip';
  String get next => _isArabic ? 'التالي' : 'Next';
  String get getStarted => _isArabic ? 'ابدأ الآن' : 'Get Started';
  String get back => _isArabic ? 'رجوع' : 'Back';

  String get slide1Title =>
      _isArabic ? 'اكتشف أشهى المأكولات' : 'Discover Culinary Delights';
  String get slide1Subtitle => _isArabic
      ? 'استكشف قوائم الطعام المتنوعة من أفضل المطاعم المحلية وتناول أطباقك المفضلة'
      : 'Explore diverse menus from top local restaurants and savor your favorite dishes.';

  String get slide2Title =>
      _isArabic ? 'تجربة طلب سلسة ومميزة' : 'Seamless Ordering Experience';
  String get slide2Subtitle => _isArabic
      ? 'تصفح الأطباق، خصص وجبتك بسهولة، واستمتع بتجربة طعام فريدة وسريعة'
      : 'Browse dishes, customize your meal easily, and enjoy a unique, fast dining experience.';

  String get slide3Title =>
      _isArabic ? 'جودة وطعم لا يُنسى' : 'Unmatched Taste & Quality';
  String get slide3Subtitle => _isArabic
      ? 'انضم إلى لقمة اليوم وابدأ رحلتك مع نكهات استثنائية وأطباق طازجة يوميًا'
      : 'Join Luqma today and start your journey with exceptional flavors and fresh dishes daily.';
}
