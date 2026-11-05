import 'package:flutter/widgets.dart';

class AddressTranslations {
  AddressTranslations(this.locale);

  final Locale locale;

  bool get _isArabic => locale.languageCode == 'ar';

  String get setupTitle =>
      _isArabic ? 'إعداد عنوان التوصيل' : 'Set up your delivery address';

  String get setupSubtitle => _isArabic
      ? 'أضف عنوانك الأول للمتابعة إلى الصفحة الرئيسية'
      : 'Add your first address to continue to Home';

  String get emptyTitle =>
      _isArabic ? 'لا يوجد عنوان محفوظ' : 'No saved addresses';

  String get emptyMessage => _isArabic
      ? 'أضف عنوانك حتى نتمكن من توصيل طلباتك بدقة'
      : 'Add your address so we can deliver your orders accurately';

  String get addAddress => _isArabic ? 'إضافة عنوان' : 'Add address';

  String get addAddressHint => _isArabic
      ? 'سيتم فتح خريطة اختيار الموقع في الخطوة التالية'
      : 'Map picker will open in the next step';

  String get myAddressesTitle =>
      _isArabic ? 'عناويني' : 'My addresses';

  String get loading => _isArabic ? 'جارٍ التحميل' : 'Loading';

  String get loadFailed => _isArabic
      ? 'تعذر تحميل العناوين'
      : "We couldn't load your addresses";

  String get retry => _isArabic ? 'حاول مرة أخرى' : 'Try again';

  String get addressListSemanticLabel =>
      _isArabic ? 'قائمة العناوين' : 'Address list';

  String get defaultBadge => _isArabic ? 'افتراضي' : 'Default';

  String get homeLabel => _isArabic ? 'المنزل' : 'Home';
  String get workLabel => _isArabic ? 'العمل' : 'Work';
  String get otherLabel => _isArabic ? 'أخرى' : 'Other';

  String labelFor(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return homeLabel;
      case 'work':
        return workLabel;
      default:
        return otherLabel;
    }
  }

  String get comingSoonTitle =>
      _isArabic ? 'خريطة اختيار الموقع قادم قريبًا' : 'Map picker coming soon';

  String get comingSoonMessage => _isArabic
      ? 'سيتم ربط هذه الخطوة بخريطة اختيار الموقع في المرحلة القادمة'
      : 'This will connect to the map location picker in the next step';

  String get comingSoonAction => _isArabic ? 'حسنًا' : 'Got it';
}
