import 'catalog_json.dart';
import 'catalog_response_envelope_model.dart';
import 'store_model.dart';

class StorePageModel {
  StorePageModel({
    required List<StoreModel> items,
    required this.pageNumber,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  }) : items = List<StoreModel>.unmodifiable(items);

  final List<StoreModel> items;
  final int pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  factory StorePageModel.fromJson(Object? value) {
    // User-confirmed success shape: envelope.data is the page object.
    // Root-level items or undocumented alternative wrappers are rejected.
    final json = catalogObject(
        CatalogResponseEnvelopeModel.fromJson(value).requireSuccess());
    final items = json['items'];
    final page = catalogInt(json, 'pageNumber');
    final pages = catalogInt(json, 'totalPages');
    final count = catalogInt(json, 'totalCount');
    if (items is! List<Object?> || page < 0 || pages < 0 || count < 0) {
      throw const FormatException('Invalid store page');
    }
    return StorePageModel(
      items: catalogLenientList(items, StoreModel.fromJson, label: 'store'),
      pageNumber: page,
      totalPages: pages,
      totalCount: count,
      hasPreviousPage: catalogOptionalBool(json, 'hasPreviousPage') ?? false,
      hasNextPage: catalogOptionalBool(json, 'hasNextPage') ?? false,
    );
  }
}
