import 'package:equatable/equatable.dart';

/// Authoritative paging information; list length is NOT an end-of-list signal.
class CatalogPage<T> extends Equatable {
  CatalogPage({
    required List<T> items,
    required this.pageNumber,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  }) : items = List<T>.unmodifiable(items);

  final List<T> items;
  final int pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  @override
  List<Object?> get props => [
        items,
        pageNumber,
        totalPages,
        totalCount,
        hasPreviousPage,
        hasNextPage,
      ];
}
