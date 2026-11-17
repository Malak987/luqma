import 'package:equatable/equatable.dart';

import 'favorite_menu_item.dart';

/// Bounded, account-scoped persisted projection of Favorites.
class FavoritesCacheSnapshot extends Equatable {
  FavoritesCacheSnapshot({
    required Iterable<String> favoriteIds,
    required List<FavoriteMenuItem> items,
    required this.totalCount,
    required this.pageNumber,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.indexComplete,
    required this.savedAt,
  })  : favoriteIds = Set<String>.unmodifiable(
          favoriteIds.map((id) => id.toLowerCase()),
        ),
        items = List<FavoriteMenuItem>.unmodifiable(items);

  final Set<String> favoriteIds;
  final List<FavoriteMenuItem> items;
  final int totalCount;
  final int pageNumber;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool indexComplete;
  final DateTime savedAt;

  @override
  List<Object?> get props => <Object?>[
        favoriteIds,
        items,
        totalCount,
        pageNumber,
        totalPages,
        hasNextPage,
        hasPreviousPage,
        indexComplete,
        savedAt,
      ];
}
