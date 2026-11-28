import '../../../../core/error/failures.dart';
import '../entities/menu_item.dart';
import '../queries/catalog_identifiers.dart';
import '../queries/menu_item_query.dart';
import '../repositories/store_menu_repository.dart';

/// Finds the actual active product using the documented unscoped paged GET.
/// Favorites do not contain the product choices and cannot be converted to one.
class FindMenuItemUseCase {
  const FindMenuItemUseCase(this._repository);
  final StoreMenuRepository _repository;

  Future<MenuItem?> call(String id) async {
    if (!isCatalogId(id)) {
      throw const FailureException(Failure(FailureCode.validation));
    }
    for (var pageNumber = 1; pageNumber <= 200; pageNumber++) {
      final page = await _repository.getItems(MenuItemQuery(
        storeId: '',
        pageNumber: pageNumber,
        pageSize: 20,
      ));
      if (page.pageNumber != pageNumber || page.items.any((e) => !e.isActive)) {
        throw const FailureException(Failure(FailureCode.unknown));
      }
      for (final item in page.items) {
        if (item.id.toLowerCase() == id.toLowerCase()) return item;
      }
      if (!page.hasNextPage) return null;
    }
    throw const FailureException(Failure(FailureCode.unknown));
  }
}
