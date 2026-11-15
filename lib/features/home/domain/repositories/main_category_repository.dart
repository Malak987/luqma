import '../entities/home_category.dart';

abstract interface class MainCategoryRepository {
  Future<List<HomeCategory>> getAllMainCategories();
}
