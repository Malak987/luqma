import '../entities/home_category.dart';
import '../repositories/main_category_repository.dart';

class GetAllMainCategoriesUseCase {
  const GetAllMainCategoriesUseCase(this._repository);

  final MainCategoryRepository _repository;

  /// Only active categories are customer-visible. Keep this policy and the
  /// display ordering out of widgets, without mutating repository-owned data.
  Future<List<HomeCategory>> call() async {
    final categories = await _repository.getAllMainCategories();
    final activeCategories = categories
        .where((category) => category.isActive)
        .toList(growable: false)
      ..sort(
          (first, second) => first.displayOrder.compareTo(second.displayOrder));
    return List<HomeCategory>.unmodifiable(activeCategories);
  }
}
