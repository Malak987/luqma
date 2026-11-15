import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/store.dart';
import '../../domain/queries/catalog_identifiers.dart';
import '../../domain/queries/catalog_paging.dart';
import '../../domain/queries/store_filters.dart';
import '../../domain/queries/store_query.dart';
import '../../domain/usecases/get_active_cuisines_use_case.dart';
import '../../domain/usecases/get_stores_use_case.dart';
import 'store_discovery_state.dart';

class StoreDiscoveryCubit extends Cubit<StoreDiscoveryState> {
  StoreDiscoveryCubit({
    required this.mainCategoryId,
    required GetActiveCuisinesUseCase getActiveCuisines,
    required GetStoresUseCase getStores,
    required CatalogPaging paging,
  })  : _getActiveCuisines = getActiveCuisines,
        _getStores = getStores,
        _paging = paging,
        super(StoreDiscoveryState());

  final String mainCategoryId;
  final GetActiveCuisinesUseCase _getActiveCuisines;
  final GetStoresUseCase _getStores;
  final CatalogPaging _paging;
  bool _started = false;
  bool _refreshing = false;
  int _generation = 0;
  StoreQuery? _firstPageRequest;
  Future<void>? _cuisineRequest;

  Future<void> load() async {
    if (isClosed || _started) return;
    _started = true;
    if (!isCatalogId(mainCategoryId)) {
      const failure = Failure(FailureCode.validation,
          debugMessage: 'Invalid category context');
      emit(state.copyWith(
        cuisines: CuisineSectionState(
            status: CatalogStatus.failure, failure: failure),
        stores:
            StoreListingState(status: CatalogStatus.failure, failure: failure),
      ));
      return;
    }
    // Each branch handles its own failure. Slow/broken cuisines cannot gate stores.
    await Future.wait<void>([_loadCuisines(), _reloadStores()]);
  }

  Future<void> selectCuisine(String? id) async {
    if (isClosed || _sameId(id, state.selectedCuisineId)) return;
    if (id != null &&
        (!isCatalogId(id) ||
            !state.cuisines.items.any((item) => _sameId(item.id, id)))) return;
    emit(state.copyWith(selectedCuisineId: id, clearCuisine: id == null));
    await _reloadStores();
  }

  Future<void> setOpenNowOnly(bool value) async {
    if (isClosed || value == state.openNowOnly) return;
    emit(state.copyWith(openNowOnly: value));
    await _reloadStores();
  }

  void setSearchQuery(String text) {
    final query = text.trim();
    if (isClosed || query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
  }

  /// Applies the whole filter sheet in one go: one state change and, only if a
  /// server-side filter changed, one reload.
  Future<void> applyFilters({
    required String? cuisineId,
    required bool openNowOnly,
    required StorePriceRange? priceRange,
    required StoreSort sort,
    required StoreOrderMode orderMode,
  }) async {
    if (isClosed) return;
    final knownCuisine = cuisineId == null ||
        (isCatalogId(cuisineId) &&
            state.cuisines.items.any((item) => _sameId(item.id, cuisineId)));
    final nextCuisine = knownCuisine ? cuisineId : state.selectedCuisineId;
    final serverChanged = !_sameId(nextCuisine, state.selectedCuisineId) ||
        openNowOnly != state.openNowOnly;
    final next = state.copyWith(
      selectedCuisineId: nextCuisine,
      clearCuisine: nextCuisine == null,
      openNowOnly: openNowOnly,
      priceRange: priceRange,
      clearPriceRange: priceRange == null,
      sort: sort,
      orderMode: orderMode,
    );
    if (!serverChanged) {
      emit(next);
      return;
    }
    await _reloadStores(stateOverride: next);
  }

  /// Clears every filter and the search text.
  Future<void> clearAllFilters() async {
    if (isClosed) return;
    final hadServerFilters = state.hasServerFilters;
    final hadClientFilters = state.hasActiveFilters ||
        state.orderMode != StoreOrderMode.delivery;
    if (!hadServerFilters && !hadClientFilters && state.searchQuery.isEmpty) {
      return;
    }

    final clearedState = state.copyWith(
      clearCuisine: true,
      openNowOnly: false,
      clearSearch: true,
      clearPriceRange: true,
      sort: StoreSort.recommended,
      orderMode: StoreOrderMode.delivery,
    );
    if (!hadServerFilters) {
      emit(clearedState);
      return;
    }
    await _reloadStores(stateOverride: clearedState);
  }

  Future<void> retryCuisines() => _loadCuisines();
  Future<void> retryStores() => _reloadStores();
  Future<void> loadNextPage() => _loadNextPage();
  Future<void> retryNextPage() => _loadNextPage(retry: true);

  Future<void> refresh() async {
    if (isClosed || _refreshing || !isCatalogId(mainCategoryId)) return;
    _refreshing = true;
    final generation = _generation;
    try {
      // If metadata removes a selection, _loadCuisines resets to All and issues
      // exactly one new query. Do not issue another identical page-one request.
      await _loadCuisines();
      if (!isClosed && generation == _generation) await _reloadStores();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _loadCuisines() {
    if (isClosed || !isCatalogId(mainCategoryId)) return Future<void>.value();
    return _cuisineRequest ??= _fetchCuisines().whenComplete(() {
      _cuisineRequest = null;
    });
  }

  Future<void> _fetchCuisines() async {
    emit(state.copyWith(
        cuisines: CuisineSectionState(
      status: CatalogStatus.loading,
      items: state.cuisines.items,
    )));
    try {
      final cuisines = await _getActiveCuisines();
      if (isClosed) return;
      final reset = state.selectedCuisineId != null &&
          !cuisines
              .any((cuisine) => _sameId(cuisine.id, state.selectedCuisineId));
      emit(state.copyWith(
        cuisines: CuisineSectionState(
          status:
              cuisines.isEmpty ? CatalogStatus.empty : CatalogStatus.success,
          items: cuisines,
        ),
        clearCuisine: reset,
      ));
      if (reset) await _reloadStores();
    } on FailureException catch (error) {
      _cuisinesFailed(error.failure);
    } catch (_) {
      _cuisinesFailed(const Failure(FailureCode.unknown));
    }
  }

  void _cuisinesFailed(Failure failure) {
    if (isClosed) return;
    emit(state.copyWith(
        cuisines: CuisineSectionState(
      status: CatalogStatus.failure,
      items: state.cuisines.items,
      failure: failure,
    )));
  }

  StoreQuery _query(int page, {StoreDiscoveryState? fromState}) {
    final filters = fromState ?? state;
    return StoreQuery(
      mainCategoryId: mainCategoryId,
      cuisineId: filters.selectedCuisineId,
      openNowOnly: filters.openNowOnly,
      pageNumber: page,
      pageSize: _paging.pageSize,
    );
  }

  Future<void> _reloadStores({StoreDiscoveryState? stateOverride}) async {
    if (isClosed) return;
    final startingState = stateOverride ?? state;
    final query = _query(_paging.firstPage, fromState: startingState);
    if (_firstPageRequest == query &&
        state.stores.status == CatalogStatus.loading) return;
    final generation = ++_generation;
    _firstPageRequest = query;
    emit(startingState.copyWith(
        stores: StoreListingState(status: CatalogStatus.loading)));
    try {
      final page = await _getStores(query);
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(
          stores: StoreListingState(
        status: page.items.isEmpty && !page.hasNextPage
            ? CatalogStatus.empty
            : CatalogStatus.success,
        items: _deduplicate(page.items),
        pageNumber: page.pageNumber,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        hasNextPage: page.hasNextPage,
      )));
    } on FailureException catch (error) {
      _storesFailed(error.failure, generation);
    } catch (_) {
      _storesFailed(const Failure(FailureCode.unknown), generation);
    } finally {
      if (generation == _generation) _firstPageRequest = null;
    }
  }

  void _storesFailed(Failure failure, int generation) {
    if (isClosed || generation != _generation) return;
    emit(state.copyWith(
        stores: StoreListingState(
      status: CatalogStatus.failure,
      failure: failure,
    )));
  }

  Future<void> _loadNextPage({bool retry = false}) async {
    if (isClosed) return;
    final current = state.stores;
    if (current.status != CatalogStatus.success ||
        !current.hasNextPage ||
        current.pageNumber == null ||
        current.isLoadingMore ||
        (!retry && current.nextPageFailure != null)) return;
    final generation = _generation;
    final query = _query(current.pageNumber! + 1);
    emit(state.copyWith(stores: current.withPagination(loading: true)));
    try {
      final page = await _getStores(query);
      if (isClosed || generation != _generation) return;
      final items = _deduplicate([...current.items, ...page.items]);
      emit(state.copyWith(
          stores: StoreListingState(
        status: items.isEmpty && !page.hasNextPage
            ? CatalogStatus.empty
            : CatalogStatus.success,
        items: items,
        pageNumber: page.pageNumber,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        hasNextPage: page.hasNextPage,
      )));
    } on FailureException catch (error) {
      _nextPageFailed(error.failure, generation);
    } catch (_) {
      _nextPageFailed(const Failure(FailureCode.unknown), generation);
    }
  }

  void _nextPageFailed(Failure failure, int generation) {
    if (isClosed || generation != _generation) return;
    emit(state.copyWith(stores: state.stores.withPagination(failure: failure)));
  }

  List<Store> _deduplicate(List<Store> items) => <String, Store>{
        for (final store in items) store.id.toLowerCase(): store
      }.values.toList(growable: false);

  bool _sameId(String? a, String? b) => a?.toLowerCase() == b?.toLowerCase();
}
