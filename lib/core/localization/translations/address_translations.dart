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

  // --- Map Location Picker (Step 3) ---
  String get mapPickerTitle => _isArabic ? 'اختر الموقع' : 'Select location';
  String get mapPickerInstructions => _isArabic
      ? 'حرك الخريطة حتى يشير الدبوس إلى موقعك بدقة'
      : 'Move the map so the pin points to your exact location';

  String get mapPickerFallbackNotice => _isArabic
      ? 'موقع تقريبي (سوهاج) — حرك الخريطة أو اضغط إعادة التمركز'
      : 'Approximate location (Sohag) — move map or tap recenter';

  String get mapPickerRecenter => _isArabic ? 'إعادة التمركز' : 'Recenter';
  String get mapPickerRecenterSemanticLabel =>
      _isArabic ? 'إعادة التمركز إلى موقعي الحالي' : 'Recenter to my current location';

  String get mapPickerConfirm => _isArabic ? 'تأكيد الموقع' : 'Confirm location';
  String get mapPickerConfirmSemanticLabel =>
      _isArabic ? 'تأكيد الموقع المحدد' : 'Confirm selected location';

  String get mapPickerLocating =>
      _isArabic ? 'جارٍ تحديد الموقع…' : 'Locating…';

  String get mapPickerAttribution => '© OpenStreetMap contributors';

  String get mapPickerErrorServiceDisabled => _isArabic
      ? 'خدمات الموقع معطلة'
      : 'Location services are disabled';

  String get mapPickerErrorPermissionDenied => _isArabic
      ? 'تم رفض إذن الموقع'
      : 'Location permission denied';

  String get mapPickerErrorPermanentlyDenied => _isArabic
      ? 'تم رفض إذن الموقع نهائيًا — فعّله من الإعدادات'
      : 'Location permission permanently denied — enable in settings';

  String get mapPickerErrorRetrievalFailed => _isArabic
      ? 'تعذر الحصول على موقعك الحالي'
      : 'Could not get current location';

  String mapPickerCoordinatesLabel(double lat, double lng) =>
      _isArabic
          ? 'الإحداثيات: ${lat.toStringAsFixed(5)}، ${lng.toStringAsFixed(5)}'
          : 'Coordinates: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  String get mapPickerIsApproximateLabel =>
      _isArabic ? 'موقع تقريبي' : 'Approximate location';

  String get mapPickerIsDeviceLabel =>
      _isArabic ? 'موقع جهازك' : 'Your device location';
}
