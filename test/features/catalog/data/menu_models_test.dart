import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/data/models/menu_category_model.dart';
import 'package:luqma_app/features/catalog/data/models/menu_category_response_model.dart';
import 'package:luqma_app/features/catalog/data/models/menu_item_model.dart';
import 'package:luqma_app/features/catalog/data/models/menu_item_page_model.dart';

import '../support/menu_fixtures.dart';

void main() {
  test(
      'MenuCategory data is a direct array, with exact store/order/count metadata',
      () {
    final model = MenuCategoryResponseModel.fromJson(
        catalogEnvelope(data: [menuCategoryJson()]));
    expect(model.items.single.toDomain(), menuCategory());
    expect(model.items.single.imageUrl, isNull);
    expect(() => model.items.clear(), throwsUnsupportedError);
    expect(MenuCategoryResponseModel.fromJson(catalogEnvelope(data: [])).items,
        isEmpty);
    for (final data in [
      null,
      {'items': []},
      {'data': []},
      '[]'
    ]) {
      expect(
          () => MenuCategoryResponseModel.fromJson(catalogEnvelope(data: data)),
          throwsFormatException);
    }
  });

  test(
      'MenuItem decodes only the nested data.items page and preserves all metadata',
      () {
    final page = MenuItemPageModel.fromJson(menuResponseJson(
        items: [menuItemJson()],
        number: 3,
        pages: 9,
        count: 100,
        previous: true,
        next: true));
    expect(page.items.single.toDomain(), menuItem());
    expect([
      page.pageNumber,
      page.totalPages,
      page.totalCount,
      page.hasPreviousPage,
      page.hasNextPage
    ], [
      3,
      9,
      100,
      true,
      true
    ]);
    expect(() => page.items.clear(), throwsUnsupportedError);
    final rawPage = menuResponseJson()['data'];
    expect(() => MenuItemPageModel.fromJson(rawPage), throwsFormatException);
    for (final data in [
      null,
      [],
      {'data': rawPage},
      {'items': null}
    ]) {
      expect(() => MenuItemPageModel.fromJson(catalogEnvelope(data: data)),
          throwsFormatException);
    }
  });

  test(
      'nullable/missing weight and optional options/addons do not invent configuration',
      () {
    for (final json in [
      menuItemJson(),
      menuItemJson()
        ..remove('weight')
        ..remove('options')
        ..remove('addons'),
      menuItemJson(options: null, addons: null)
    ]) {
      final item = MenuItemModel.fromJson(json).toDomain();
      expect(item.weight, isNull);
      expect(item.options, isEmpty);
      expect(item.addons, isEmpty);
    }
    final json = menuItemJson(weight: 0.75, soldByWeight: true)
      ..addAll({'weightMin': 1, 'weightMax': 3, 'weightStep': .5});
    final item = MenuItemModel.fromJson(json).toDomain();
    expect(item.weight, .75);
    expect(item.isSoldByWeight, isTrue); // Create-only extra fields are ignored
    expect(item.nameAr, 'طبق النيل');
    expect(item.descriptionEn, 'A synthetic product description');
  });

  test(
      'options and addons map separate IDs, bilingual text, numeric prices and optional images',
      () {
    final json = menuItemJson(
        options: [optionJson()], addons: [addonJson(id: optionId)]);
    final item = MenuItemModel.fromJson(json).toDomain();
    expect(item.options.single.id, optionId);
    expect(item.addons.single.id,
        optionId); // not conflated, even with identical IDs
    expect(item.options.single.nameAr, 'عادي');
    expect(item.options.single.price, 25.5);
    expect(item.addons.single.nameEn, 'Cheese');
    expect(item.addons.single.price, 4);
    expect(item.addons.single.imageUrl, isNull);
    expect(() => item.options.clear(), throwsUnsupportedError);
    expect(() => item.addons.clear(), throwsUnsupportedError);
    expect(
        MenuItemModel.fromJson(menuItemJson(addons: [
          addonJson()..['imageUrl'] = 'https://example.test/addon.png'
        ])).toDomain().addons.single.imageUrl,
        'https://example.test/addon.png');
  });

  test(
      'sale requires an actual finite compare-at price greater than current price',
      () {
    expect(menuItem(compare: 30).hasSale, isTrue);
    for (final value in [0, 25.5, 20, double.nan, double.infinity]) {
      expect(menuItem(compare: value).hasSale, isFalse);
    }
  });

  test(
      'malformed required IDs/booleans/numbers/arrays fail, never become empty products',
      () {
    for (final entry in <String, Object?>{
      'id': 'not-a-uuid',
      'menuCategoryId': null,
      'price': '25',
      // Live API returns null for an absent comparison price; malformed
      // non-numeric values must still fail.
      'compareAtPrice': '30',
      'isActive': 1,
      'isSoldByWeight': 'false',
      'weight': '1 kg',
      'options': {},
      'addons': false,
    }.entries) {
      expect(
          () =>
              MenuItemModel.fromJson(menuItemJson()..[entry.key] = entry.value),
          throwsFormatException);
    }
    for (final value in [double.nan, double.infinity]) {
      expect(() => MenuItemModel.fromJson(menuItemJson(price: value)),
          throwsFormatException);
    }
    expect(
        () =>
            MenuCategoryModel.fromJson(menuCategoryJson()..['storeId'] = 'bad'),
        throwsFormatException);
    expect(
        () =>
            MenuCategoryModel.fromJson(menuCategoryJson()..['itemsCount'] = -1),
        throwsFormatException);
  });

  test('unsuccessful envelopes are interpreted before operation-specific data',
      () {
    final response = catalogEnvelope(data: null, succeeded: false);
    expect(() => MenuCategoryResponseModel.fromJson(response),
        throwsA(isA<RemoteException>()));
    expect(() => MenuItemPageModel.fromJson(response),
        throwsA(isA<RemoteException>()));
  });
}
