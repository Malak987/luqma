import 'package:flutter/widgets.dart';

class FavoritesTranslations {
  FavoritesTranslations(this.locale);
  final Locale locale;
  bool get _ar => locale.languageCode == 'ar';

  String get title => _ar ? 'المفضلة' : 'Favourites';
  String count(int value) => _ar
      ? '${_number(value)} صنف في المفضلة'
      : value == 1
      ? '1 favourite'
      : '$value favourites';
  String get loading => _ar ? 'جارٍ تحميل المفضلة' : 'Loading favourites';
  String get emptyTitle => _ar ? 'لا توجد أصناف مفضلة بعد' : 'No favourites yet';
  String get emptyMessage => _ar
      ? 'اضغط على القلب بجانب أي صنف لحفظه هنا.'
      : 'Tap a heart beside any menu item to save it here.';
  String get loadFailed => _ar
      ? 'تعذر تحميل المفضلة'
      : 'We could not load your favourites';
  String get retry => _ar ? 'حاول مرة أخرى' : 'Try again';
  String get loadMore => _ar ? 'عرض المزيد من الأصناف' : 'Show more favourites';
  String get paginationFailed => _ar
      ? 'تعذر تحميل المزيد. الأصناف الحالية ما زالت متاحة.'
      : 'More favourites could not load. Your current items are still available.';
  String get add => _ar ? 'إضافة إلى المفضلة' : 'Add to favourites';
  String get remove => _ar ? 'إزالة من المفضلة' : 'Remove from favourites';
  String get added => _ar ? 'تمت الإضافة إلى المفضلة' : 'Added to favourites';
  String get removed => _ar ? 'تمت الإزالة من المفضلة' : 'Removed from favourites';
  String get actionFailed => _ar
      ? 'تعذر تحديث المفضلة. حاول مرة أخرى.'
      : 'We could not update your favourites. Please try again.';
  String get synchronizationFailed => _ar
      ? 'تم التحديث، لكن تعذر تحديث المفضلة. اسحب لإعادة المحاولة.'
      : 'The update completed, but favourites could not refresh. Pull to retry.';
  String get unavailable => _ar ? 'غير متاح حاليًا' : 'Currently unavailable';

  String _number(int value) {
    if (!_ar) return '$value';
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return '$value'.replaceAllMapped(
      RegExp(r'[0-9]'),
      (match) => digits[int.parse(match[0]!)],
    );
  }
}
