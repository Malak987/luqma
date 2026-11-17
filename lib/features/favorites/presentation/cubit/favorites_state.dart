import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/favorite_menu_item.dart';

enum FavoritesStatus { initial, loading, empty, populated, error }

/// One immutable source for the Favorites page, count badge and every menu
/// heart. Membership map keys are normalized lower-case menu-item UUIDs.
class FavoritesState extends Equatable {
  FavoritesState({
    this.status = FavoritesStatus.initial,
    List<FavoriteMenuItem> items = const <FavoriteMenuItem>[],
    Map<String, bool> favoriteByMenuItemId = const <String, bool>{},
    Set<String> checkingMenuItemIds = const <String>{},
    this.pageNumber,
    this.totalPages = 0,
    this.totalCount = 0,
    this.hasPreviousPage = false,
    this.hasNextPage = false,
    this.loadingMore = false,
    this.failure,
    this.nextPageFailure,
    this.isMutating = false,
    this.indexComplete = false,
    this.cacheTimestamp,
  })  : items = List<FavoriteMenuItem>.unmodifiable(items),
        byMenuItemId = Map<String, FavoriteMenuItem>.unmodifiable(
          <String, FavoriteMenuItem>{
            for (final item in items) item.menuItemId.toLowerCase(): item,
          },
        ),
        favoriteByMenuItemId = Map<String, bool>.unmodifiable(
          <String, bool>{
            for (final entry in favoriteByMenuItemId.entries)
              entry.key.toLowerCase(): entry.value,
          },
        ),
        checkingMenuItemIds = Set<String>.unmodifiable(
          checkingMenuItemIds.map((id) => id.toLowerCase()),
        );

  final FavoritesStatus status;
  final List<FavoriteMenuItem> items;
  final Map<String, FavoriteMenuItem> byMenuItemId;
  final Map<String, bool> favoriteByMenuItemId;
  final Set<String> checkingMenuItemIds;
  final int? pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final bool loadingMore;
  final Failure? failure;
  final Failure? nextPageFailure;
  final bool isMutating;
  final bool indexComplete;
  final DateTime? cacheTimestamp;

  bool get isLoading => status == FavoritesStatus.loading;
  bool get isEmpty => status == FavoritesStatus.empty;
  bool get isPopulated => status == FavoritesStatus.populated;
  bool get hasError => status == FavoritesStatus.error;
  int get badgeCount => totalCount;

  bool knowsFavorite(String menuItemId) =>
      indexComplete ||
      favoriteByMenuItemId.containsKey(menuItemId.trim().toLowerCase());

  bool isFavorite(String menuItemId) =>
      favoriteByMenuItemId[menuItemId.trim().toLowerCase()] ?? false;

  bool isChecking(String menuItemId) =>
      checkingMenuItemIds.contains(menuItemId.trim().toLowerCase());

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<FavoriteMenuItem>? items,
    Map<String, bool>? favoriteByMenuItemId,
    Set<String>? checkingMenuItemIds,
    int? pageNumber,
    int? totalPages,
    int? totalCount,
    bool? hasPreviousPage,
    bool? hasNextPage,
    bool? loadingMore,
    Failure? failure,
    Failure? nextPageFailure,
    bool clearFailure = false,
    bool clearNextPageFailure = false,
    bool? isMutating,
    bool? indexComplete,
    DateTime? cacheTimestamp,
  }) =>
      FavoritesState(
        status: status ?? this.status,
        items: items ?? this.items,
        favoriteByMenuItemId: favoriteByMenuItemId ?? this.favoriteByMenuItemId,
        checkingMenuItemIds: checkingMenuItemIds ?? this.checkingMenuItemIds,
        pageNumber: pageNumber ?? this.pageNumber,
        totalPages: totalPages ?? this.totalPages,
        totalCount: totalCount ?? this.totalCount,
        hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
        hasNextPage: hasNextPage ?? this.hasNextPage,
        loadingMore: loadingMore ?? this.loadingMore,
        failure: clearFailure ? null : failure ?? this.failure,
        nextPageFailure: clearNextPageFailure
            ? null
            : nextPageFailure ?? this.nextPageFailure,
        isMutating: isMutating ?? this.isMutating,
        indexComplete: indexComplete ?? this.indexComplete,
        cacheTimestamp: cacheTimestamp ?? this.cacheTimestamp,
      );

  @override
  List<Object?> get props => <Object?>[
        status,
        items,
        favoriteByMenuItemId,
        checkingMenuItemIds,
        pageNumber,
        totalPages,
        totalCount,
        hasPreviousPage,
        hasNextPage,
        loadingMore,
        failure,
        nextPageFailure,
        isMutating,
        indexComplete,
        cacheTimestamp,
      ];
}
