import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/features/catalog/data/models/menu_item_page_model.dart';

import '../support/menu_fixtures.dart';

void main() {
  test('a page containing a null compare-at price still loads all products',
      () {
    final response = menuResponseJson(items: [
      menuItemJson(),
      menuItemJson(id: otherMenuItemId)..['compareAtPrice'] = null,
    ], count: 2);
    final page = MenuItemPageModel.fromJson(response);
    expect(page.items.map((item) => item.id), [menuItemId, otherMenuItemId]);
    expect(page.items.last.toDomain().compareAtPrice, isNull);
    expect(page.items.last.toDomain().hasSale, isFalse);
    expect(page.items.last.toDomain().discountPercent, 0);
  });
  test('a missing product image does not reject the page', () {
    for (final item in [
      menuItemJson()..['imageUrl'] = null,
      menuItemJson()..remove('imageUrl'),
    ]) {
      final page =
          MenuItemPageModel.fromJson(menuResponseJson(items: [item], count: 1));
      expect(page.items.single.imageUrl, isEmpty);
    }
    final malformed = menuItemJson()..['imageUrl'] = 42;
    expect(
        () => MenuItemPageModel.fromJson(menuResponseJson(items: [malformed])),
        throwsFormatException);
  });
}
