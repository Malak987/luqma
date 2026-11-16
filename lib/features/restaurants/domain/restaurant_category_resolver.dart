import '../../home/domain/entities/home_category.dart';

/// Resolves only exact category names verified in the catalog fixtures.
/// The API has no category-kind flag, so unknown names remain unresolved.
abstract final class RestaurantCategoryResolver {
  static const Set<String> _verifiedNames = <String>{
    'مطاعم',
    'restaurants',
  };

  static HomeCategory? resolve(List<HomeCategory> categories) {
    for (final category in categories.where((item) => item.isActive)) {
      if (_verifiedNames.contains(category.nameAr.trim().toLowerCase()) ||
          _verifiedNames.contains(category.nameEn.trim().toLowerCase())) {
        return category;
      }
    }
    return null;
  }
}
