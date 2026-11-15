import '../../../../core/error/failures.dart';
import '../../domain/entities/catalog_page.dart';
import '../../domain/entities/cuisine.dart';
import '../../domain/entities/store.dart';
import '../../domain/queries/store_query.dart';
import '../../domain/repositories/store_discovery_repository.dart';
import '../datasources/store_discovery_remote_data_source.dart';

class StoreDiscoveryRepositoryImpl implements StoreDiscoveryRepository {
  const StoreDiscoveryRepositoryImpl(this._remote);
  final StoreDiscoveryRemoteDataSource _remote;

  @override
  Future<List<Cuisine>> getActiveCuisines() => _mapFailure(() async =>
      List<Cuisine>.unmodifiable((await _remote.getActiveCuisines())
          .map((model) => model.toDomain())));

  @override
  Future<CatalogPage<Store>> getStores(StoreQuery query) =>
      _mapFailure(() async {
        final page = await _remote.getStores(query);
        return CatalogPage<Store>(
          items: page.items
              .map((model) => model.toDomain())
              .toList(growable: false),
          pageNumber: page.pageNumber,
          totalPages: page.totalPages,
          totalCount: page.totalCount,
          hasPreviousPage: page.hasPreviousPage,
          hasNextPage: page.hasNextPage,
        );
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
          debugMessage: 'Catalog operation could not be completed'));
    }
  }
}
