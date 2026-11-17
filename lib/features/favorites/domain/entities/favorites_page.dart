import 'package:equatable/equatable.dart';

import 'favorite_menu_item.dart';

/// Server-authoritative pagination metadata. A short page is never treated as
/// the end of the collection; hasNextPage is the source of truth.
class FavoritesPage extends Equatable {
  FavoritesPage({
    required List<FavoriteMenuItem> items,
    required this.pageNumber,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  }) : items = List<FavoriteMenuItem>.unmodifiable(items);

  final List<FavoriteMenuItem> items;
  final int pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  @override
  List<Object?> get props => <Object?>[
        items,
        pageNumber,
        totalPages,
        totalCount,
        hasPreviousPage,
        hasNextPage,
      ];
}
