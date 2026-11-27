import '../../../home/domain/entities/home_category.dart';
import '../entities/menu_category.dart';

/// Non-sensitive, server-supplied category snapshots. A null result means no
/// valid snapshot exists; an empty list is a valid successful server response.
abstract interface class CategorySnapshotCache {
  List<HomeCategory>? readMainCategories();
  Future<void> writeMainCategories(List<HomeCategory> categories);
  List<MenuCategory>? readMenuCategories(String storeId);
  Future<void> writeMenuCategories(
      String storeId, List<MenuCategory> categories);
}
