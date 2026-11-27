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

  /// Short welcoming headline under the greeting in the Home header.
  String get greetingHeadline =>
      _isArabic ? 'ماذا تشتهي اليوم؟' : 'What are you craving today?';

  String get searchHint => _isArabic
      ? 'ابحث عن طبقك المفضل أو مطعم...'
      : 'Search for your favorite dish or restaurant...';

  /// Tooltip for the search field's clear action.
  String get clearSearch => _isArabic ? 'مسح البحث' : 'Clear search';

  /// Shown when the search entry point is used before the search API exists.
  String get searchUnavailable =>
      _isArabic ? 'البحث سيتوفر قريبًا' : 'Search will be available soon';

  /// Badge on a restaurant that has no ratings yet.
  String get newBadge => _isArabic ? 'جديد' : 'New';

  String get seeAll => _isArabic ? 'عرض الكل' : 'See all';
  String get showMore => _isArabic ? 'عرض المزيد' : 'Show more';

  /// Small caption above a saved delivery address.
  String get deliverTo => _isArabic ? 'التوصيل إلى' : 'Deliver to';

  /// Home header address row when no address is stored yet.
  String get selectDeliveryAddress =>
      _isArabic ? 'اختر عنوان التوصيل' : 'Select delivery address';

  /// Screen-reader hint for the tappable address row.
  String get changeAddressHint =>
      _isArabic ? 'اضغط لتغيير عنوان التوصيل' : 'Tap to change the delivery address';

  String get changeAddressSemanticLabel =>
      _isArabic ? 'تغيير عنوان التوصيل' : 'Change delivery address';

  String get notificationsLabel => _isArabic ? 'الإشعارات' : 'Notifications';

  String get notificationsUnavailable => _isArabic
      ? 'الإشعارات ستتوفر قريبًا'
      : 'Notifications will be available soon';

  // ---- Promo banner --------------------------------------------------------

  // The banner advertises the catalog itself. It deliberately carries no
  // percentage or deadline: the Store API publishes neither, so any figure here
  // would be invented marketing copy.
  String get promoTag => _isArabic ? 'من مطاعم المدينة' : 'From your city';
  String get promoTitle =>
      _isArabic ? 'اكتشف أطباقًا جديدة' : 'Discover new dishes';

  /// Second headline line of the default banner.
  String get promoHighlight => _isArabic ? 'كل يوم' : 'Every day';
  String get promoSubtitle => _isArabic
      ? 'تصفّح المطاعم المتاحة واطلب ما يناسب ذوقك'
      : 'Browse the restaurants around you and order what you love';
  String get promoCta => _isArabic ? 'تصفّح المطاعم' : 'Browse restaurants';

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
