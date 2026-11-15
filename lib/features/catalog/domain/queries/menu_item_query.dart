import 'package:equatable/equatable.dart';
import 'menu_item_filters.dart';

class MenuItemQuery extends Equatable {
  const MenuItemQuery(
      {required this.storeId,
      required this.pageNumber,
      required this.pageSize,
      this.filters = const MenuItemFilters()});
  final String storeId;
  final int pageNumber;
  final int pageSize;
  final MenuItemFilters filters;
  // sortBy is intentionally not exposed until accepted backend values exist.

  @override
  List<Object?> get props => [storeId, pageNumber, pageSize, filters];
}
