import 'favorite_json.dart';
import 'favorite_menu_item_model.dart';
import 'favorite_response_envelope_model.dart';

class FavoritePageModel {
  FavoritePageModel({
    required List<FavoriteMenuItemModel> items,
    required this.pageNumber,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  }) : items = List<FavoriteMenuItemModel>.unmodifiable(items);

  final List<FavoriteMenuItemModel> items;
  final int pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  factory FavoritePageModel.fromJson(Object? value) {
    final json = favoriteObject(
      FavoriteResponseEnvelopeModel.fromJson(value)
          .requireSuccess('GetMyFavorites'),
      'GetMyFavorites data',
    );
    final items = json['items'];
    if (items is! List<Object?>) {
      throw const FormatException('Invalid GetMyFavorites items');
    }
    return FavoritePageModel(
      items: items.map(FavoriteMenuItemModel.fromJson).toList(growable: false),
      pageNumber: favoriteRequiredNonNegativeInt(json, 'pageNumber'),
      totalPages: favoriteRequiredNonNegativeInt(json, 'totalPages'),
      totalCount: favoriteRequiredNonNegativeInt(json, 'totalCount'),
      hasPreviousPage: favoriteRequiredBool(json, 'hasPreviousPage'),
      hasNextPage: favoriteRequiredBool(json, 'hasNextPage'),
    );
  }
}
