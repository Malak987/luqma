import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/favorite_menu_item.dart';

enum FavoritesStatus { initial, loading, empty, populated, error }

/// One immutable source for the Favorites page, the count badge and every
/// menu heart. Membership keys are normalized lower-case menu-item UUIDs.
///
/// The collections are never mutated after an emit; the cubit always builds
/// new ones, which keeps this class `const`-constructible and cheap to copy.
class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.initial,
    this.items = const <FavoriteMenuItem>[],
    this.favoriteIds = const <String>{},
    this.pendingIds = const <String>{},
    this.pageNumber,
    this.totalPages = 0,
    this.totalCount = 0,
    this.hasNextPage = false,
    this.loadingMore = false,
    this.failure,
    this.nextPageFailure,
    this.indexComplete = false,
    this.cacheTimestamp,
  });

  final FavoritesStatus status;

  /// Items with their display data (a prefix of the list until every page is
  /// loaded). A favourite whose data has not arrived yet is only in
  /// [favoriteIds].
  final List<FavoriteMenuItem> items;

  /// Membership of every known favourite. Complete when [indexComplete].
  final Set<String> favoriteIds;

  /// Ids whose latest toggle is still being confirmed by the server.
  final Set<String> pendingIds;
  final int? pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool loadingMore;
  final Failure? failure;
  final Failure? nextPageFailure;

  /// [favoriteIds] holds every favourite, so absence means "not a favourite".
  final bool indexComplete;
  final DateTime? cacheTimestamp;

  bool get isLoading => status == FavoritesStatus.loading;
  bool get isEmpty => status == FavoritesStatus.empty;
  bool get isPopulated => status == FavoritesStatus.populated;
  bool get hasError => status == FavoritesStatus.error;
  int get badgeCount => totalCount;

  bool knowsFavorite(String menuItemId) =>
      indexComplete || favoriteIds.contains(menuItemId.trim().toLowerCase());

  bool isFavorite(String menuItemId) =>
      favoriteIds.contains(menuItemId.trim().toLowerCase());

  bool isPending(String menuItemId) =>
      pendingIds.contains(menuItemId.trim().toLowerCase());

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<FavoriteMenuItem>? items,
    Set<String>? favoriteIds,
    Set<String>? pendingIds,
    int? pageNumber,
    int? totalPages,
    int? totalCount,
    bool? hasNextPage,
    bool? loadingMore,
    Failure? failure,
    Failure? nextPageFailure,
    bool clearFailure = false,
    bool clearNextPageFailure = false,
    bool? indexComplete,
    DateTime? cacheTimestamp,
  }) => FavoritesState(
    status: status ?? this.status,
    items: items ?? this.items,
    favoriteIds: favoriteIds ?? this.favoriteIds,
    pendingIds: pendingIds ?? this.pendingIds,
    pageNumber: pageNumber ?? this.pageNumber,
    totalPages: totalPages ?? this.totalPages,
    totalCount: totalCount ?? this.totalCount,
    hasNextPage: hasNextPage ?? this.hasNextPage,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: clearFailure ? null : failure ?? this.failure,
    nextPageFailure: clearNextPageFailure
        ? null
        : nextPageFailure ?? this.nextPageFailure,
    indexComplete: indexComplete ?? this.indexComplete,
    cacheTimestamp: cacheTimestamp ?? this.cacheTimestamp,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    favoriteIds,
    pendingIds,
    pageNumber,
    totalPages,
    totalCount,
    hasNextPage,
    loadingMore,
    failure,
    nextPageFailure,
    indexComplete,
    cacheTimestamp,
  ];
}
