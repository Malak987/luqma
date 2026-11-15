import 'catalog_json.dart';
import 'catalog_response_envelope_model.dart';
import 'menu_item_model.dart';

class MenuItemPageModel {
  MenuItemPageModel({
    required List<MenuItemModel> items,
    required this.pageNumber,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  }) : items = List<MenuItemModel>.unmodifiable(items);
  final List<MenuItemModel> items;
  final int pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  factory MenuItemPageModel.fromJson(Object? value) {
    final json = catalogObject(
        CatalogResponseEnvelopeModel.fromJson(value).requireSuccess());
    final items = json['items'];
    final page = catalogInt(json, 'pageNumber');
    final pages = catalogInt(json, 'totalPages');
    final count = catalogInt(json, 'totalCount');
    if (items is! List<Object?> || page < 0 || pages < 0 || count < 0) {
      throw const FormatException('Invalid MenuItem data.items page');
    }
    return MenuItemPageModel(
        items: items.map(MenuItemModel.fromJson).toList(growable: false),
        pageNumber: page,
        totalPages: pages,
        totalCount: count,
        hasPreviousPage: catalogBool(json, 'hasPreviousPage'),
        hasNextPage: catalogBool(json, 'hasNextPage'));
  }
}
