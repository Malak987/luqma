import 'package:flutter/widgets.dart';

extension LocaleDirectionX on Locale {
  bool get isArabic => languageCode == 'ar';

  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;
}
