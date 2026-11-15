import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/queries/menu_item_filters.dart';

enum MenuStatus { initial, loading, success, empty, failure }

class MenuCategoryState extends Equatable {
  MenuCategoryState(
      {this.status = MenuStatus.initial,
      List<MenuCategory> items = const [],
      this.failure})
      : items = List<MenuCategory>.unmodifiable(items);
  final MenuStatus status;
  final List<MenuCategory> items;
  final Failure? failure;

  @override
  List<Object?> get props => [status, items, failure];
}

class MenuItemListingState extends Equatable {
  factory MenuItemListingState({
    MenuStatus status = MenuStatus.initial,
    List<MenuItem> items = const [],
    int? pageNumber,
    int totalPages = 0,
    int totalCount = 0,
    bool hasPreviousPage = false,
    bool hasNextPage = false,
    bool loadingMore = false,
    Failure? failure,
    Failure? nextPageFailure,
  }) =>
      MenuItemListingState._(
          status: status,
          items: List<MenuItem>.unmodifiable(items),
          byId: Map<String, MenuItem>.unmodifiable(
              {for (final item in items) item.id.toLowerCase(): item}),
          pageNumber: pageNumber,
          totalPages: totalPages,
          totalCount: totalCount,
          hasPreviousPage: hasPreviousPage,
          hasNextPage: hasNextPage,
          loadingMore: loadingMore,
          failure: failure,
          nextPageFailure: nextPageFailure);

  const MenuItemListingState._(
      {required this.status,
      required this.items,
      required this.byId,
      required this.pageNumber,
      required this.totalPages,
      required this.totalCount,
      required this.hasPreviousPage,
      required this.hasNextPage,
      this.loadingMore = false,
      this.failure,
      this.nextPageFailure});
  final MenuStatus status;
  final List<MenuItem> items;
  final Map<String, MenuItem> byId;
  final int? pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final bool loadingMore;
  final Failure? failure;
  final Failure? nextPageFailure;

  /// Footer-only changes reuse the same immutable list reference.
  MenuItemListingState withPagination({bool loading = false, Failure? error}) =>
      MenuItemListingState._(
          status: status,
          items: items,
          byId: byId,
          pageNumber: pageNumber,
          totalPages: totalPages,
          totalCount: totalCount,
          hasPreviousPage: hasPreviousPage,
          hasNextPage: hasNextPage,
          loadingMore: loading,
          failure: failure,
          nextPageFailure: error);

  @override
  List<Object?> get props => [
        status,
        items,
        pageNumber,
        totalPages,
        totalCount,
        hasPreviousPage,
        hasNextPage,
        loadingMore,
        failure,
        nextPageFailure
      ];
}

class StoreMenuState extends Equatable {
  StoreMenuState(
      {required this.storeId,
      this.filters = const MenuItemFilters(),
      MenuCategoryState? categories,
      MenuItemListingState? products})
      : categories = categories ?? MenuCategoryState(),
        products = products ?? MenuItemListingState();
  final String storeId;
  final MenuItemFilters filters;
  final MenuCategoryState categories;
  final MenuItemListingState products;

  StoreMenuState copyWith(
          {MenuItemFilters? filters,
          MenuCategoryState? categories,
          MenuItemListingState? products}) =>
      StoreMenuState(
          storeId: storeId,
          filters: filters ?? this.filters,
          categories: categories ?? this.categories,
          products: products ?? this.products);

  @override
  List<Object?> get props => [storeId, filters, categories, products];
}
