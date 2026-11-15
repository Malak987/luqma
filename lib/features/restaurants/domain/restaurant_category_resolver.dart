import '../../home/domain/entities/home_category.dart';

/// Picks the main category that holds the restaurants.
///
/// The API has no "this is the restaurants category" flag yet (see
/// BACKEND_MISSING_DATA.md), so the category is matched by name, like the
/// category artwork on Home. When nothing matches it falls back to the first
/// active category, so the tab is never empty because of a renamed category.
abstract final class RestaurantCategoryResolver {
  static const List<String> _keywords = <String>[
    'مطاعم',
    'مطعم',
    'مأكولات',
    'أطعمة',
    'طعام',
    'restaurant',
    'restaurants',
    'food',
    'foods',
  ];

  static HomeCategory? resolve(List<HomeCategory> categories) {
    final active = categories.where((category) => category.isActive).toList();
    final pool = active.isEmpty ? categories : active;
    for (final category in pool) {
      final names = '${category.nameAr} ${category.nameEn}'.toLowerCase();
      if (_keywords.any(names.contains)) return category;
    }
    return pool.isEmpty ? null : pool.first;
  }
}
