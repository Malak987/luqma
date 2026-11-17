import 'package:luqma_app/features/favorites/domain/entities/favorite_menu_item.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorites_page.dart';
import 'package:luqma_app/features/favorites/domain/repositories/favorites_repository.dart';

const favoriteId = '40000000-aaaa-4000-8000-000000000001';
const favoriteMenuItemId = '40000000-bbbb-4000-8000-000000000002';
const otherFavoriteMenuItemId = '40000000-cccc-4000-8000-000000000003';

Map<String, Object?> favoriteEnvelope({
  required Object? data,
  bool succeeded = true,
  String message = 'ok',
}) =>
    <String, Object?>{
      'message': message,
      'data': data,
      'isSucceeded': succeeded,
      'timestamp': '2026-11-16T17:51:17.0237074Z',
    };

Map<String, Object?> favoriteItemJson({
  String id = favoriteId,
  String menuItemId = favoriteMenuItemId,
  String nameAr = 'طبق النيل',
  String nameEn = 'Nile dish',
  String descriptionAr = 'طبق محلي',
  String descriptionEn = 'Local dish',
  Object? imageUrl = 'https://images.example.test/nile.jpg',
  num price = 125,
  Object? compareAtPrice = 150,
  bool isAvailable = true,
  String addedAt = '2026-11-16T17:51:17.0237074Z',
}) =>
    <String, Object?>{
      'id': id,
      'menuItemId': menuItemId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'imageUrl': imageUrl,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'isAvailable': isAvailable,
      'addedAt': addedAt,
    };

Map<String, Object?> favoritePageJson({
  List<Object?> items = const <Object?>[],
  int pageNumber = 1,
  int totalPages = 1,
  int totalCount = 0,
  bool hasPreviousPage = false,
  bool hasNextPage = false,
}) =>
    <String, Object?>{
      'items': items,
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'totalCount': totalCount,
      'hasPreviousPage': hasPreviousPage,
      'hasNextPage': hasNextPage,
    };

FavoriteMenuItem favoriteItem({
  String id = favoriteId,
  String menuItemId = favoriteMenuItemId,
  String nameAr = 'طبق النيل',
  String nameEn = 'Nile dish',
  String descriptionAr = 'طبق محلي',
  String descriptionEn = 'Local dish',
  String? imageUrl = 'https://images.example.test/nile.jpg',
  num price = 125,
  num? compareAtPrice = 150,
  bool isAvailable = true,
}) =>
    FavoriteMenuItem(
      id: id,
      menuItemId: menuItemId,
      nameAr: nameAr,
      nameEn: nameEn,
      descriptionAr: descriptionAr,
      descriptionEn: descriptionEn,
      imageUrl: imageUrl,
      price: price,
      compareAtPrice: compareAtPrice,
      isAvailable: isAvailable,
      addedAt: '2026-11-16T17:51:17.0237074Z',
    );

FavoritesPage favoritesPage({
  List<FavoriteMenuItem> items = const <FavoriteMenuItem>[],
  int pageNumber = 1,
  int totalPages = 1,
  int totalCount = 0,
  bool hasPreviousPage = false,
  bool hasNextPage = false,
}) =>
    FavoritesPage(
      items: items,
      pageNumber: pageNumber,
      totalPages: totalPages,
      totalCount: totalCount,
      hasPreviousPage: hasPreviousPage,
      hasNextPage: hasNextPage,
    );

class FakeFavoritesRepository implements FavoritesRepository {
  FavoritesPage currentPage = favoritesPage();
  int currentCount = 0;
  final Map<String, bool> statuses = <String, bool>{};
  Object? error;
  String? lastAdded;
  String? lastRemoved;
  String? lastIsFavorite;
  int pageReads = 0;
  int countReads = 0;
  Future<FavoriteMenuItem> Function(String menuItemId)? onAdd;
  Future<void> Function(String menuItemId)? onRemove;
  Future<FavoritesPage> Function(int pageNumber, int pageSize)? onGetPage;
  Future<bool> Function(String menuItemId)? onIsFavorite;
  Future<int> Function()? onGetCount;

  @override
  Future<FavoriteMenuItem> addToFavorites(String menuItemId) async {
    if (error != null) throw error!;
    lastAdded = menuItemId;
    return onAdd == null
        ? favoriteItem(menuItemId: menuItemId)
        : await onAdd!(menuItemId);
  }

  @override
  Future<void> removeFromFavorites(String menuItemId) async {
    if (error != null) throw error!;
    lastRemoved = menuItemId;
    if (onRemove != null) await onRemove!(menuItemId);
  }

  @override
  Future<FavoritesPage> getMyFavorites({
    required int pageNumber,
    required int pageSize,
  }) async {
    if (error != null) throw error!;
    pageReads++;
    return onGetPage == null
        ? currentPage
        : await onGetPage!(pageNumber, pageSize);
  }

  @override
  Future<bool> isFavorite(String menuItemId) async {
    if (error != null) throw error!;
    lastIsFavorite = menuItemId;
    return onIsFavorite == null
        ? statuses[menuItemId.toLowerCase()] ?? false
        : await onIsFavorite!(menuItemId);
  }

  @override
  Future<int> getCount() async {
    if (error != null) throw error!;
    countReads++;
    return onGetCount == null ? currentCount : await onGetCount!();
  }
}
