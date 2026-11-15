// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get brandName => 'لقمة';

  @override
  String get brandTagline => 'LUQMA CULINARY';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get forgotPassword => 'استعادة كلمة المرور';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get verification => 'التحقق';

  @override
  String get home => 'الرئيسية';

  @override
  String get comingSoon => 'هذه الصفحة قادمة قريبًا';

  @override
  String get back => 'رجوع';

  @override
  String get emailOrUsername => 'اسم المستخدم أو البريد';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get continueWith => 'أو المتابعة عبر';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get registerNow => 'سجل الآن';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح';

  @override
  String get loginFailed => 'تعذر تسجيل الدخول';

  @override
  String get networkError => 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى';

  @override
  String get invalidCredentials => 'بيانات الدخول غير صحيحة';

  @override
  String get unknownError => 'حدث خطأ غير متوقع. حاول مرة أخرى';

  @override
  String get loginLoading => 'جارٍ تسجيل الدخول';

  @override
  String get appleLogin => 'المتابعة باستخدام آبل';

  @override
  String get facebookLogin => 'المتابعة باستخدام فيسبوك';

  @override
  String get googleLogin => 'المتابعة باستخدام جوجل';

  @override
  String get validationRequired => 'هذا الحقل مطلوب';

  @override
  String get validationUsernameOrEmail =>
      'أدخل بريدًا إلكترونيًا أو اسم مستخدم صحيحًا';

  @override
  String get validationPasswordLength =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get addressSetupTitle => 'إعداد عنوان التوصيل';

  @override
  String get addressSetupSubtitle =>
      'أضف عنوانك الأول للمتابعة إلى الصفحة الرئيسية';

  @override
  String get addressEmptyTitle => 'لا يوجد عنوان محفوظ';

  @override
  String get addressEmptyMessage => 'أضف عنوانك حتى نتمكن من توصيل طلباتك بدقة';

  @override
  String get addressAddAction => 'إضافة عنوان';

  @override
  String get addressLoading => 'جارٍ التحميل';

  @override
  String get addressLoadFailed => 'تعذر تحميل العناوين';

  @override
  String get addressRetry => 'حاول مرة أخرى';

  @override
  String get mapPickerTitle => 'اختر الموقع';

  @override
  String get mapPickerInstructions =>
      'حرك الخريطة حتى يشير الدبوس إلى موقعك بدقة';

  @override
  String get mapPickerFallbackNotice =>
      'موقع تقريبي (سوهاج) — حرك الخريطة أو اضغط إعادة التمركز';

  @override
  String get mapPickerRecenter => 'إعادة التمركز';

  @override
  String get mapPickerConfirm => 'تأكيد الموقع';

  @override
  String get mapPickerAttribution => '© OpenStreetMap contributors';

  @override
  String get mapPickerLocating => 'جارٍ تحديد الموقع…';
}
