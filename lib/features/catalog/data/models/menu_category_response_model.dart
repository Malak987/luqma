import 'catalog_response_envelope_model.dart';
import 'menu_category_model.dart';

class MenuCategoryResponseModel {
  MenuCategoryResponseModel(List<MenuCategoryModel> items)
      : items = List<MenuCategoryModel>.unmodifiable(items);
  final List<MenuCategoryModel> items;

  factory MenuCategoryResponseModel.fromJson(Object? value) {
    final data = CatalogResponseEnvelopeModel.fromJson(value).requireSuccess();
    // Exact confirmed contract: a direct array, NEVER data.items.
    if (data is! List<Object?>) {
      throw const FormatException('MenuCategory data must be a direct array');
    }
    return MenuCategoryResponseModel(
        data.map(MenuCategoryModel.fromJson).toList(growable: false));
  }
}
