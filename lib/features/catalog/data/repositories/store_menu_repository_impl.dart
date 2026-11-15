import '../../../../core/error/failures.dart';
import '../../domain/entities/catalog_page.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/queries/menu_item_query.dart';
import '../../domain/repositories/store_menu_repository.dart';
import '../datasources/store_menu_remote_data_source.dart';

class StoreMenuRepositoryImpl implements StoreMenuRepository {
  const StoreMenuRepositoryImpl(this._remote);
  final StoreMenuRemoteDataSource _remote;

  @override
  Future<List<MenuCategory>> getActiveCategories(String storeId) =>
      _mapFailure(() async => List<MenuCategory>.unmodifiable(
          (await _remote.getActiveCategories(storeId))
              .map((model) => model.toDomain())));

  @override
  Future<CatalogPage<MenuItem>> getItems(MenuItemQuery query) =>
      _mapFailure(() async {
        final page = await _remote.getItems(query);
        return CatalogPage<MenuItem>(
            items: page.items
                .map((model) => model.toDomain())
                .toList(growable: false),
            pageNumber: page.pageNumber,
            totalPages: page.totalPages,
            totalCount: page.totalCount,
            hasPreviousPage: page.hasPreviousPage,
            hasNextPage: page.hasNextPage);
      });

  Future<T> _mapFailure<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RemoteException catch (error) {
      throw FailureException(Failure(error.code, debugMessage: error.message));
    } on FailureException {
      rethrow;
    } catch (_) {
      throw const FailureException(Failure(FailureCode.unknown,
          debugMessage: 'Menu operation could not be completed'));
    }
  }
}
