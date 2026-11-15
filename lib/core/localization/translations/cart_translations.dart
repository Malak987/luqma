import 'package:flutter/widgets.dart';

import 'catalog_translations.dart';

/// Copy of the local cart and its bar.
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

  /// Rounded to two decimals so sums never show floating point noise.
  String amount(num value) =>
      CatalogTranslations(locale).money((value * 100).round() / 100);

  String get openCart => _ar ? 'عرض السلة' : 'View cart';
  String get replaceTitle => _ar ? 'بدء سلة جديدة؟' : 'Start a new cart?';
  String replaceMessage(String storeName) => _ar
      ? 'سلتك تحتوي على منتجات من «$storeName». هل تريد حذفها وإضافة هذا المنتج؟'
      : 'Your cart has items from “$storeName”. Clear it and add this item?';
  String get replaceAction => _ar ? 'حذف وإضافة' : 'Clear and add';
  String get decrease => _ar ? 'تقليل الكمية' : 'Decrease quantity';
  String get increase => _ar ? 'زيادة الكمية' : 'Increase quantity';
}
