import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../catalog/domain/entities/store.dart';
import '../../../catalog/domain/repositories/category_snapshot_cache.dart';
import '../../../catalog/domain/queries/catalog_paging.dart';
import '../../../catalog/domain/queries/store_query.dart';
import '../../../catalog/domain/usecases/get_stores_use_case.dart';
import '../../../restaurants/domain/restaurant_category_resolver.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/usecases/get_all_main_categories_use_case.dart';
import 'home_state.dart';

/// Loads profile and catalog content without coupling Home to network or data
/// source details. The Store preview uses the existing catalog use case.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required SecureStorageService secureStorageService,
    required GetAllMainCategoriesUseCase getAllMainCategoriesUseCase,
    required GetStoresUseCase getStoresUseCase,
    required CatalogPaging catalogPaging,
    CategorySnapshotCache? categoryCache,
  })  : _secureStorageService = secureStorageService,
        _getAllMainCategoriesUseCase = getAllMainCategoriesUseCase,
        _getStoresUseCase = getStoresUseCase,
        _catalogPaging = catalogPaging,
        _categoryCache = categoryCache,
        super(const HomeState.initial());

  static const int _restaurantPreviewLimit = 3;

  final SecureStorageService _secureStorageService;
  final GetAllMainCategoriesUseCase _getAllMainCategoriesUseCase;
  final GetStoresUseCase _getStoresUseCase;
  final CatalogPaging _catalogPaging;
  final CategorySnapshotCache? _categoryCache;

  Future<void>? _categoriesRequest;
  Future<void>? _restaurantsRequest;

  Future<void> load() async {
    if (isClosed || state.isLoading || state.status == HomeStatus.loaded) {
      return;
    }

    emit(state.copyWith(status: HomeStatus.loading, clearFailure: true));
    final cached = _categoryCache?.readMainCategories();
    if (cached != null &&
        state.categoriesStatus == HomeCategoriesStatus.initial) {
      emit(state.copyWith(
          categories: cached,
          categoriesStatus: cached.isEmpty
              ? HomeCategoriesStatus.empty
              : HomeCategoriesStatus.success));
      unawaited(loadRestaurants());
    }
    await Future.wait<void>(<Future<void>>[
      _loadProfile(),
      loadCategories(forceRefresh: cached != null),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final userName =
          _normalizedName(await _secureStorageService.getUserName());
      if (isClosed) return;
      emit(
        state.copyWith(
          status: HomeStatus.loaded,
          userName: userName,
          clearUserName: userName == null,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          failure: Failure(
            FailureCode.unknown,
            debugMessage: error.toString(),
          ),
        ),
      );
    }
  }

  /// Loads categories once, then resolves the real Restaurants category before
  /// requesting stores. Category retry does not reread profile storage.
  Future<void> loadCategories({bool forceRefresh = false}) {
    if (isClosed) return Future<void>.value();
    final inFlight = _categoriesRequest;
    if (inFlight != null) return inFlight;
    if (!forceRefresh &&
        (state.categoriesStatus == HomeCategoriesStatus.success ||
            state.categoriesStatus == HomeCategoriesStatus.empty ||
            state.categoriesStatus == HomeCategoriesStatus.error)) {
      return Future<void>.value();
    }
    return _categoriesRequest = _fetchCategories().whenComplete(() {
      _categoriesRequest = null;
    });
  }

  Future<void> _fetchCategories() async {
    final hasSnapshot =
        state.categoriesStatus == HomeCategoriesStatus.success ||
            state.categoriesStatus == HomeCategoriesStatus.empty;
    if (!hasSnapshot) {
      emit(state.copyWith(
          categoriesStatus: HomeCategoriesStatus.loading,
          clearCategoriesFailure: true));
    }
    try {
      final previousCategoryId =
          RestaurantCategoryResolver.resolve(state.categories)?.id;
      final categories = await _getAllMainCategoriesUseCase();
      if (isClosed) return;
      final immutable = List<HomeCategory>.unmodifiable(categories);
      emit(
        state.copyWith(
          categoriesStatus: immutable.isEmpty
              ? HomeCategoriesStatus.empty
              : HomeCategoriesStatus.success,
          categories: immutable,
          clearCategoriesFailure: true,
        ),
      );
      try {
        await _categoryCache?.writeMainCategories(immutable);
      } catch (_) {}
      final currentCategoryId =
          RestaurantCategoryResolver.resolve(immutable)?.id;
      if (previousCategoryId?.toLowerCase() !=
          currentCategoryId?.toLowerCase()) {
        final previousRequest = _restaurantsRequest;
        if (previousRequest != null) await previousRequest;
        if (isClosed) return;
        await loadRestaurants(forceRefresh: true);
      } else {
        await loadRestaurants();
      }
    } on FailureException catch (error) {
      if (isClosed) return;
      if (hasSnapshot) {
        emit(state.copyWith(categoriesFailure: error.failure));
        return;
      }
      emit(
        state.copyWith(
          categoriesStatus: HomeCategoriesStatus.error,
          categoriesFailure: error.failure,
          restaurantsStatus: HomeRestaurantsStatus.unavailable,
          restaurants: const <Store>[],
          clearRestaurantsFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      if (hasSnapshot) {
        emit(state.copyWith(
            categoriesFailure:
                Failure(FailureCode.unknown, debugMessage: error.toString())));
        return;
      }
      emit(
        state.copyWith(
          categoriesStatus: HomeCategoriesStatus.error,
          categoriesFailure: Failure(
            FailureCode.unknown,
            debugMessage: error.toString(),
          ),
          restaurantsStatus: HomeRestaurantsStatus.unavailable,
          restaurants: const <Store>[],
          clearRestaurantsFailure: true,
        ),
      );
    }
  }

  Future<void> retryCategories() => loadCategories(forceRefresh: true);

  /// Requests only the first bounded preview page. It never guesses a category
  /// ID and can be retried independently from profile/category loading.
  Future<void> loadRestaurants({bool forceRefresh = false}) {
    if (isClosed) return Future<void>.value();
    final inFlight = _restaurantsRequest;
    if (inFlight != null) return inFlight;
    if (!forceRefresh &&
        (state.restaurantsStatus == HomeRestaurantsStatus.success ||
            state.restaurantsStatus == HomeRestaurantsStatus.empty ||
            state.restaurantsStatus == HomeRestaurantsStatus.unavailable)) {
      return Future<void>.value();
    }
    final category = RestaurantCategoryResolver.resolve(state.categories);
    if (state.categoriesStatus != HomeCategoriesStatus.success ||
        category == null) {
      emit(state.copyWith(
        restaurants: const <Store>[],
        restaurantsStatus: HomeRestaurantsStatus.unavailable,
        clearRestaurantsFailure: true,
      ));
      return Future<void>.value();
    }
    return _restaurantsRequest =
        _fetchRestaurants(category.id).whenComplete(() {
      _restaurantsRequest = null;
    });
  }

  Future<void> retryRestaurants() => loadRestaurants(forceRefresh: true);

  Future<void> _fetchRestaurants(String mainCategoryId) async {
    emit(state.copyWith(
      restaurantsStatus: HomeRestaurantsStatus.loading,
      clearRestaurantsFailure: true,
    ));
    final pageSize = _catalogPaging.pageSize < _restaurantPreviewLimit
        ? _catalogPaging.pageSize
        : _restaurantPreviewLimit;
    try {
      final page = await _getStoresUseCase(
        StoreQuery(
          mainCategoryId: mainCategoryId,
          pageNumber: _catalogPaging.firstPage,
          pageSize: pageSize,
        ),
      );
      if (isClosed ||
          RestaurantCategoryResolver.resolve(state.categories)
                  ?.id
                  .toLowerCase() !=
              mainCategoryId.toLowerCase()) return;
      final stores = List<Store>.unmodifiable(page.items);
      emit(state.copyWith(
        restaurants: stores,
        restaurantsStatus: stores.isEmpty
            ? HomeRestaurantsStatus.empty
            : HomeRestaurantsStatus.success,
        clearRestaurantsFailure: true,
      ));
    } on FailureException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(
        restaurantsStatus: HomeRestaurantsStatus.error,
        restaurantsFailure: error.failure,
      ));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(
        restaurantsStatus: HomeRestaurantsStatus.error,
        restaurantsFailure: Failure(
          FailureCode.unknown,
          debugMessage: error.toString(),
        ),
      ));
    }
  }

  /// Blank names count as missing, so the header can fall back gracefully.
  String? _normalizedName(String? userName) {
    final trimmed = userName?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
