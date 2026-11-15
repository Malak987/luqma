import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/cuisine.dart';
import '../../domain/entities/store.dart';
import '../../domain/queries/store_filters.dart';

enum CatalogStatus { initial, loading, success, empty, failure }

class CuisineSectionState extends Equatable {
  CuisineSectionState(
      {this.status = CatalogStatus.initial,
      List<Cuisine> items = const [],
      this.failure})
      : items = List<Cuisine>.unmodifiable(items);

  final CatalogStatus status;
  final List<Cuisine> items;
  final Failure? failure;

  @override
  List<Object?> get props => [status, items, failure];
}

class StoreListingState extends Equatable {
  factory StoreListingState({
    CatalogStatus status = CatalogStatus.initial,
    List<Store> items = const [],
    int? pageNumber,
    int totalPages = 0,
    int totalCount = 0,
    bool hasNextPage = false,
    bool isLoadingMore = false,
    Failure? failure,
    Failure? nextPageFailure,
  }) =>
      StoreListingState._(
        status: status,
        items: List<Store>.unmodifiable(items),
        pageNumber: pageNumber,
        totalPages: totalPages,
        totalCount: totalCount,
        hasNextPage: hasNextPage,
        isLoadingMore: isLoadingMore,
        failure: failure,
        nextPageFailure: nextPageFailure,
      );

  const StoreListingState._({
    required this.status,
    required this.items,
    required this.pageNumber,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    this.isLoadingMore = false,
    this.failure,
    this.nextPageFailure,
  });

  final CatalogStatus status;
  final List<Store> items;
  final int? pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool isLoadingMore;
  final Failure? failure;
  final Failure? nextPageFailure;

  StoreListingState withPagination({bool loading = false, Failure? failure}) =>
      StoreListingState._(
        status: status,
        items: items,
        pageNumber: pageNumber,
        totalPages: totalPages,
        totalCount: totalCount,
        hasNextPage: hasNextPage,
        isLoadingMore: loading,
        failure: this.failure,
        nextPageFailure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        items,
        pageNumber,
        totalPages,
        totalCount,
        hasNextPage,
        isLoadingMore,
        failure,
        nextPageFailure,
      ];
}

class StoreDiscoveryState extends Equatable {
  StoreDiscoveryState({
    CuisineSectionState? cuisines,
    StoreListingState? stores,
    this.selectedCuisineId,
    this.openNowOnly = false,
    this.searchQuery = '',
    this.priceRange,
    this.sort = StoreSort.recommended,
    this.orderMode = StoreOrderMode.delivery,
  })  : cuisines = cuisines ?? CuisineSectionState(),
        stores = stores ?? StoreListingState();

  final CuisineSectionState cuisines;
  final StoreListingState stores;
  final String? selectedCuisineId;
  final bool openNowOnly;

  /// Client-side name search over the stores loaded so far. The stores
  /// endpoint has no search parameter (see BACKEND_MISSING_DATA.md).
  final String searchQuery;

  /// Narrowing applied to the loaded stores only; the server filters nothing
  /// by price or order yet (see BACKEND_MISSING_DATA.md).
  final StorePriceRange? priceRange;
  final StoreSort sort;
  final StoreOrderMode orderMode;

  /// Filters that are sent to the server.
  bool get hasServerFilters => selectedCuisineId != null || openNowOnly;

  /// Anything narrowing or re-ordering the list (shows the "show all" button).
  bool get hasActiveFilters =>
      hasServerFilters ||
      priceRange != null ||
      sort != StoreSort.recommended;

  /// Loaded stores narrowed by [searchQuery] and [priceRange], then ordered by
  /// [sort]. Same list instance when nothing applies, so list widgets can
  /// rely on identity. Price, rating and distance are only used for stores
  /// that actually carry them.
  List<Store> get visibleStores {
    final query = searchQuery.toLowerCase();
    final range = priceRange;
    if (query.isEmpty && range == null && sort == StoreSort.recommended) {
      return stores.items;
    }
    var result = stores.items.where((store) {
      final matchesName = query.isEmpty ||
          store.nameAr.toLowerCase().contains(query) ||
          store.nameEn.toLowerCase().contains(query);
      final matchesPrice =
          range == null || store.matchesPriceRange(range.min, range.max);
      return matchesName && matchesPrice;
    }).toList(growable: false);
    if (sort == StoreSort.recommended) return result;

    // List.sort is not stable: the original index breaks ties.
    final indexed = <(int, Store)>[
      for (var i = 0; i < result.length; i++) (i, result[i]),
    ];
    int byIndex((int, Store) a, (int, Store) b) => a.$1.compareTo(b.$1);
    indexed.sort((a, b) {
      switch (sort) {
        case StoreSort.popular:
          final count = (b.$2.ratingCount ?? -1).compareTo(a.$2.ratingCount ?? -1);
          if (count != 0) return count;
          final rating = (b.$2.rating ?? -1).compareTo(a.$2.rating ?? -1);
          return rating != 0 ? rating : byIndex(a, b);
        case StoreSort.nearest:
          final da = a.$2.distanceKm, db = b.$2.distanceKm;
          if (da == null && db == null) return byIndex(a, b);
          if (da == null) return 1;
          if (db == null) return -1;
          final distance = da.compareTo(db);
          return distance != 0 ? distance : byIndex(a, b);
        case StoreSort.recommended:
          return byIndex(a, b);
      }
    });
    result = <Store>[for (final entry in indexed) entry.$2];
    return result;
  }

  StoreDiscoveryState copyWith({
    CuisineSectionState? cuisines,
    StoreListingState? stores,
    String? selectedCuisineId,
    bool clearCuisine = false,
    bool? openNowOnly,
    String? searchQuery,
    bool clearSearch = false,
    StorePriceRange? priceRange,
    bool clearPriceRange = false,
    StoreSort? sort,
    StoreOrderMode? orderMode,
  }) =>
      StoreDiscoveryState(
        cuisines: cuisines ?? this.cuisines,
        stores: stores ?? this.stores,
        selectedCuisineId:
            clearCuisine ? null : selectedCuisineId ?? this.selectedCuisineId,
        openNowOnly: openNowOnly ?? this.openNowOnly,
        searchQuery: clearSearch ? '' : searchQuery ?? this.searchQuery,
        priceRange: clearPriceRange ? null : priceRange ?? this.priceRange,
        sort: sort ?? this.sort,
        orderMode: orderMode ?? this.orderMode,
      );

  @override
  List<Object?> get props => [
        cuisines,
        stores,
        selectedCuisineId,
        openNowOnly,
        searchQuery,
        priceRange,
        sort,
        orderMode,
      ];
}
