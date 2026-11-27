import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/catalog/data/models/menu_item_model.dart';
import '../../catalog/support/menu_fixtures.dart';

void main() {
  test('nullable compare and weight remain unknown, not a fabricated price',
      () {
    final raw = menuItemJson(price: 0)
      ..['compareAtPrice'] = null
      ..['weight'] = null;
    final item = MenuItemModel.fromJson(raw).toDomain();
    expect(item.price, 0);
    expect(item.compareAtPrice, isNull);
    expect(item.weight, isNull);
    expect(item.hasSale, isFalse);
    expect(item.discountPercent, 0);
  });
  test('malformed monetary values are errors, not zero or empty results', () {
    for (final value in [null, '12', double.nan, double.infinity]) {
      expect(() => MenuItemModel.fromJson(menuItemJson()..['price'] = value),
          throwsFormatException);
    }
    for (final value in ['12', double.nan, double.infinity]) {
      expect(
          () => MenuItemModel.fromJson(
              menuItemJson()..['compareAtPrice'] = value),
          throwsFormatException);
      expect(() => MenuItemModel.fromJson(menuItemJson()..['weight'] = value),
          throwsFormatException);
    }
    expect(
        () => MenuItemModel.fromJson(
            menuItemJson(options: [optionJson()..['price'] = null])),
        throwsFormatException);
    expect(
        () => MenuItemModel.fromJson(
            menuItemJson(addons: [addonJson()..['price'] = null])),
        throwsFormatException);
  });
}
