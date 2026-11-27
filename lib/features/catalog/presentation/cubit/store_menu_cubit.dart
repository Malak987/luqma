import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/category_snapshot_cache.dart';
import '../../domain/queries/catalog_identifiers.dart';
import '../../domain/queries/catalog_paging.dart';
import '../../domain/queries/menu_item_filters.dart';
import '../../domain/queries/menu_item_query.dart';
import '../../domain/usecases/get_active_menu_categories_use_case.dart';
import '../../domain/usecases/get_menu_items_use_case.dart';
import 'store_menu_state.dart';

class StoreMenuCubit extends Cubit<StoreMenuState> {
  StoreMenuCubit(
      {required String storeId,
      required GetActiveMenuCategoriesUseCase getCategories,
      required GetMenuItemsUseCase getItems,
      required CatalogPaging paging,
      CategorySnapshotCache? categoryCache})
      : _getCategories = getCategories,
        _getItems = getItems,
        _paging = paging,
        _categoryCache = categoryCache,
        super(StoreMenuState(storeId: storeId));
  final GetActiveMenuCategoriesUseCase _getCategories;
  final GetMenuItemsUseCase _getItems;
  final CatalogPaging _paging;
  final CategorySnapshotCache? _categoryCache;
  bool _started = false;
  int _categoryGeneration = 0;
  int _productGeneration = 0;
  Future<void>? _categoryRequest;
  MenuItemQuery? _initialRequest;

  Future<void> load() async {
    if (isClosed || _started) return;
    _started = true;
    if (!isCatalogId(state.storeId)) {
      const error = Failure(FailureCode.validation,
          debugMessage: 'Invalid menu store context');
      emit(state.copyWith(
          categories:
              MenuCategoryState(status: MenuStatus.failure, failure: error),
          products: MenuItemListingState(
              status: MenuStatus.failure, failure: error)));
      return;
    }
    final cached = _categoryCache?.readMenuCategories(state.storeId);
    if (cached != null) {
      emit(state.copyWith(
          categories: MenuCategoryState(
              status: cached.isEmpty ? MenuStatus.empty : MenuStatus.success,
              items: cached)));
    }
    await Future.wait<void>([_loadCategories(), _reloadProducts()]);
  }

  /// Routes normally create a fresh Cubit. Also safe if a host changes its
  /// Store snapshot in place, including A -> B -> A with requests in flight.
  Future<void> changeStore(String storeId) async {
    if (isClosed || storeId.toLowerCase() == state.storeId.toLowerCase())
      return;
    _categoryGeneration++;
    _productGeneration++;
    _categoryRequest = null;
    _initialRequest = null;
    _started = false;
    emit(StoreMenuState(storeId: storeId));
    await load();
  }

  Future<void> selectCategory(String? id) async {
    if (isClosed ||
        id?.toLowerCase() == state.filters.menuCategoryId?.toLowerCase())
      return;
    if (id != null &&
        (!isCatalogId(id) ||
            !state.categories.items.any(
                (category) => category.id.toLowerCase() == id.toLowerCase())))
      return;
    await _changeFilters(state.filters.withCategory(id));
  }

  Future<void> search(String text) {
    final trimmed = text.trim();
    return _changeFilters(
        state.filters.withSearch(trimmed.isEmpty ? null : trimmed));
  }

  Future<void> setPriceRange(num? minimum, num? maximum) =>
      _changeFilters(state.filters.withPriceRange(minimum, maximum));
  Future<void> setSaleOnly(bool value) =>
      _changeFilters(state.filters.withSaleOnly(value));
  Future<void> retryCategories() => _loadCategories();
  Future<void> refreshCategoriesSilently() => _loadCategories();
  Future<void> retryProducts() => _reloadProducts();
  Future<void> loadNextPage() => _loadNextPage();
  Future<void> retryNextPage() => _loadNextPage(retry: true);

  Future<void> _changeFilters(MenuItemFilters filters) async {
    if (isClosed || filters == state.filters || !filters.hasValidPrices) return;
    await _reloadProducts(filters: filters);
  }

  Future<void> _loadCategories() {
    if (isClosed || !isCatalogId(state.storeId)) return Future<void>.value();
    if (_categoryRequest != null) return _categoryRequest!;
    final generation = ++_categoryGeneration;
    final storeId = state.storeId;
    return _categoryRequest =
        _fetchCategories(storeId, generation).whenComplete(() {
      if (generation == _categoryGeneration) _categoryRequest = null;
    });
  }

  Future<void> _fetchCategories(String storeId, int generation) async {
    final hasSnapshot = state.categories.status == MenuStatus.success ||
        state.categories.status == MenuStatus.empty;
    if (!hasSnapshot) {
      emit(state.copyWith(
          categories: MenuCategoryState(
              status: MenuStatus.loading, items: state.categories.items)));
    }
    try {
      final categories = await _getCategories(storeId);
      if (!_currentCategoryRequest(storeId, generation)) return;
      final selected = state.filters.menuCategoryId;
      final removed = selected != null &&
          !categories.any((category) =>
              category.id.toLowerCase() == selected.toLowerCase());
      emit(state.copyWith(
          categories: MenuCategoryState(
              status:
                  categories.isEmpty ? MenuStatus.empty : MenuStatus.success,
              items: categories)));
      try {
        await _categoryCache?.writeMenuCategories(storeId, categories);
      } catch (_) {}
      if (!_currentCategoryRequest(storeId, generation)) return;
      if (removed)
        await _reloadProducts(filters: state.filters.withCategory(null));
    } on FailureException catch (error) {
      _categoriesFailed(storeId, generation, error.failure);
    } catch (_) {
      _categoriesFailed(
          storeId, generation, const Failure(FailureCode.unknown));
    }
  }

  bool _currentCategoryRequest(String storeId, int generation) =>
      !isClosed &&
      generation == _categoryGeneration &&
      storeId == state.storeId;

  void _categoriesFailed(String storeId, int generation, Failure failure) {
    if (!_currentCategoryRequest(storeId, generation)) return;
    emit(state.copyWith(
        categories: MenuCategoryState(
            status: state.categories.status == MenuStatus.success ||
                    state.categories.status == MenuStatus.empty
                ? state.categories.status
                : MenuStatus.failure,
            items: state.categories.items,
            failure: failure)));
  }

  MenuItemQuery _query(int page) => MenuItemQuery(
      storeId: state.storeId,
      filters: state.filters,
      pageNumber: page,
      pageSize: _paging.pageSize);

  Future<void> _reloadProducts({MenuItemFilters? filters}) async {
    if (isClosed) return;
    final query = MenuItemQuery(
        storeId: state.storeId,
        filters: filters ?? state.filters,
        pageNumber: _paging.firstPage,
        pageSize: _paging.pageSize);
    if (_initialRequest == query && state.products.status == MenuStatus.loading)
      return;
    final generation = ++_productGeneration;
    _initialRequest = query;
    // New filters and cleared results/paging are one atomic state update.
    emit(state.copyWith(
        filters: query.filters,
        products: MenuItemListingState(status: MenuStatus.loading)));
    try {
      final page = await _getItems(query);
      if (isClosed || generation != _productGeneration) return;
      final items = _deduplicate(page.items);
      emit(state.copyWith(
          products: MenuItemListingState(
              status: items.isEmpty && !page.hasNextPage
                  ? MenuStatus.empty
                  : MenuStatus.success,
              items: items,
              pageNumber: page.pageNumber,
              totalPages: page.totalPages,
              totalCount: page.totalCount,
              hasPreviousPage: page.hasPreviousPage,
              hasNextPage: page.hasNextPage)));
    } on FailureException catch (error) {
      _productsFailed(generation, error.failure);
    } catch (_) {
      _productsFailed(generation, const Failure(FailureCode.unknown));
    } finally {
      if (generation == _productGeneration) _initialRequest = null;
    }
  }

  void _productsFailed(int generation, Failure failure) {
    if (isClosed || generation != _productGeneration) return;
    emit(state.copyWith(
        products: MenuItemListingState(
            status: MenuStatus.failure, failure: failure)));
  }

  Future<void> _loadNextPage({bool retry = false}) async {
    if (isClosed) return;
    final current = state.products;
    if (current.status != MenuStatus.success ||
        !current.hasNextPage ||
        current.pageNumber == null ||
        current.loadingMore ||
        (!retry && current.nextPageFailure != null)) return;
    final generation = _productGeneration;
    final query = _query(current.pageNumber! + 1);
    emit(state.copyWith(products: current.withPagination(loading: true)));
    try {
      final page = await _getItems(query);
      if (isClosed || generation != _productGeneration) return;
      final items = _deduplicate([...current.items, ...page.items]);
      emit(state.copyWith(
          products: MenuItemListingState(
              status: items.isEmpty && !page.hasNextPage
                  ? MenuStatus.empty
                  : MenuStatus.success,
              items: items,
              pageNumber: page.pageNumber,
              totalPages: page.totalPages,
              totalCount: page.totalCount,
              hasPreviousPage: page.hasPreviousPage,
              hasNextPage: page.hasNextPage)));
    } on FailureException catch (error) {
      _nextFailed(generation, error.failure);
    } catch (_) {
      _nextFailed(generation, const Failure(FailureCode.unknown));
    }
  }

  void _nextFailed(int generation, Failure failure) {
    if (isClosed || generation != _productGeneration) return;
    emit(state.copyWith(
        products: state.products.withPagination(error: failure)));
  }

  List<MenuItem> _deduplicate(List<MenuItem> items) => <String, MenuItem>{
        for (final item in items) item.id.toLowerCase(): item,
      }.values.toList(growable: false);
}
