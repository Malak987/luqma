import 'catalog_response_envelope_model.dart';
import 'cuisine_model.dart';

class CuisineResponseModel {
  CuisineResponseModel(List<CuisineModel> items)
      : items = List<CuisineModel>.unmodifiable(items);
  final List<CuisineModel> items;

  factory CuisineResponseModel.fromJson(Object? value) {
    final data = CatalogResponseEnvelopeModel.fromJson(value).requireSuccess();
    if (data is! List<Object?>) {
      throw const FormatException('Cuisine data must be a list');
    }
    return CuisineResponseModel(
        data.map(CuisineModel.fromJson).toList(growable: false));
  }
}
