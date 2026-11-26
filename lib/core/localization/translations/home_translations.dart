import 'package:flutter/widgets.dart';

/// Home-screen copy, kept beside the other catalogs so the app keeps one
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
      return _isArabic ? 'مرحباً بك' : 'Welcome';
    }
    return _isArabic ? 'مرحباً، $trimmed' : 'Hello, $trimmed';
  }

  String get searchHint => _isArabic
      ? 'ابحث عن طبقك المفضل أو مطعم...'
      : 'Search for your favorite dish or restaurant...';

  /// Shown when the search entry point is used before the search API exists.
  String get searchUnavailable =>
      _isArabic ? 'البحث سيتوفر قريبًا' : 'Search will be available soon';

  String get seeAll => _isArabic ? 'عرض الكل' : 'See all';

  String get notificationsLabel => _isArabic ? 'الإشعارات' : 'Notifications';

  String get notificationsUnavailable => _isArabic
      ? 'الإشعارات ستتوفر قريبًا'
      : 'Notifications will be available soon';

  // ---- Promo banner --------------------------------------------------------

  String get promoTag => _isArabic ? 'عرض اليوم الحصري' : "Today's exclusive offer";
  String get promoTitle =>
      _isArabic ? 'عروض خاصة تصل إلى' : 'Special offers up to';
  String get promoDiscount => '50%';
  String get promoSubtitle => _isArabic
      ? 'متاح طوال اليوم لتذوق أشهى المأكولات المميزة'
      : 'Available all day to enjoy our finest dishes';
  String get promoCta => _isArabic ? 'اطلب الآن' : 'Order now';

  // ---- Categories ----------------------------------------------------------

  String get categoriesTitle => _isArabic ? 'التصنيفات' : 'Categories';

  String get categoriesSubtitle => _isArabic
      ? 'اختر حسب صنف الطعام المحبب إليك'
      : 'Pick the type of food you love';

  String get categoriesLoading =>
      _isArabic ? 'جارٍ تحميل التصنيفات' : 'Loading categories';

  /// A successful catalog response with no active categories.
  String get categoriesEmpty => _isArabic
      ? 'لا توجد تصنيفات متاحة حاليًا'
      : 'No categories are available right now';

  String get categoriesLoadFailed => _isArabic
      ? 'تعذر تحميل التصنيفات'
      : "We couldn't load the categories";

  // ---- Restaurants ---------------------------------------------------------

  String get restaurantsTitle => _isArabic ? 'مطاعم' : 'Restaurants';

  String get restaurantsSubtitle => _isArabic
      ? 'تصفّح المطاعم المتاحة حسب التصنيف'
      : 'Browse available restaurants by category';

  /// Empty state after a successful restaurant request returns no stores.
  String get restaurantsEmpty => _isArabic
      ? 'لا توجد مطاعم متاحة حاليًا'
      : 'No restaurants are available right now';

  String get restaurantsLoading =>
      _isArabic ? 'جارٍ تحميل المطاعم' : 'Loading restaurants';

  String get restaurantsLoadFailed => _isArabic
      ? 'تعذر تحميل المطاعم'
      : "We couldn't load the restaurants";

  String get restaurantsCategoryUnavailable => _isArabic
      ? 'لا يوجد تصنيف مطاعم متاح حاليًا'
      : 'A restaurants category is not available right now';

  /// Failure copy of [HomeStatus.failure]; shown when the screen's data could
  /// not be read at all.
  String get loadFailed => _isArabic
      ? 'تعذر تحميل الصفحة الرئيسية'
      : "We couldn't load your home screen";

  String get retry => _isArabic ? 'حاول مرة أخرى' : 'Try again';
}
