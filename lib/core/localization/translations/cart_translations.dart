import 'package:flutter/widgets.dart';

import 'catalog_translations.dart';

/// Copy for the API-backed cart. Amounts deliberately use the numeric value
/// only: Cart responses do not include a currency convention.
class CartTranslations {
  CartTranslations(this.locale);

  final Locale locale;

  bool get _ar => locale.languageCode == 'ar';

  String itemsInCart(int count) {
    if (_ar) {
      final digits = CatalogTranslations(locale).number(count);
      if (count == 1) return 'عنصر واحد في السلة';
      if (count == 2) return 'عنصران في السلة';
      if (count <= 10) return '$digits عناصر في السلة';
      return '$digits عنصرًا في السلة';
    }
    return count == 1 ? '1 item in cart' : '$count items in cart';
  }

  /// Rounded only for display so API amounts never show floating-point noise.
  String amount(num value) =>
      CatalogTranslations(locale).number((value * 100).round() / 100);

  String get title => _ar ? 'السلة' : 'Cart';
  String get openCart => _ar ? 'عرض السلة' : 'View cart';
  String get loading => _ar ? 'جارٍ تحميل السلة' : 'Loading cart';
  String get emptyTitle => _ar ? 'سلتك فارغة' : 'Your cart is empty';
  String get emptyMessage => _ar
      ? 'أضف أصنافًا من القائمة لتظهر هنا.'
      : 'Add items from a menu and they will appear here.';
  String get loadFailed =>
      _ar ? 'تعذر تحميل السلة' : 'We could not load your cart';
  String get retry => _ar ? 'حاول مرة أخرى' : 'Try again';
  String get subTotal => _ar ? 'المجموع الفرعي' : 'Subtotal';
  String get unitPrice => _ar ? 'سعر الوحدة' : 'Unit price';
  String get lineTotal => _ar ? 'إجمالي الصنف' : 'Line total';
  String get options => _ar ? 'الخيار' : 'Option';
  String get addons => _ar ? 'الإضافات' : 'Add-ons';
  String get unavailable => _ar ? 'غير متاح حاليًا' : 'Currently unavailable';
  String get removed => _ar ? 'تمت إزالته' : 'Removed';
  String get added => _ar ? 'تمت الإضافة إلى السلة' : 'Added to cart';
  String get updated => _ar ? 'تم تحديث كمية الصنف' : 'Item quantity updated';
  String get actionFailed => _ar
      ? 'تعذر تحديث السلة. حاول مرة أخرى.'
      : 'We could not update your cart. Please try again.';
  String get synchronizationFailed => _ar
      ? 'تم تنفيذ التحديث، لكن تعذر تحديث السلة. اسحب لإعادة المحاولة.'
      : 'The update completed, but the cart could not refresh. Pull to retry.';
  String get clear => _ar ? 'إفراغ السلة' : 'Clear cart';
  String get clearConfirmTitle => _ar ? 'إفراغ السلة؟' : 'Clear cart?';
  String get clearConfirmMessage => _ar
      ? 'سيؤدي هذا إلى إزالة كل الأصناف من سلتك.'
      : 'This will remove every item from your cart.';
  String get cleared => _ar ? 'تم إفراغ السلة' : 'Cart cleared';
  String get remove => _ar ? 'إزالة الصنف من السلة' : 'Remove item from cart';
  String get decrease => _ar ? 'تقليل الكمية' : 'Decrease quantity';
  String get increase => _ar ? 'زيادة الكمية' : 'Increase quantity';
}
