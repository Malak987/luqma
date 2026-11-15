import 'package:equatable/equatable.dart';

class MenuItemFilters extends Equatable {
  const MenuItemFilters(
      {this.menuCategoryId,
      this.search,
      this.minPrice,
      this.maxPrice,
      this.saleOnly = false});
  final String? menuCategoryId;
  final String? search;
  final num? minPrice;
  final num? maxPrice;
  final bool saleOnly;

  MenuItemFilters withCategory(String? id) => MenuItemFilters(
      menuCategoryId: id,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      saleOnly: saleOnly);
  MenuItemFilters withSearch(String? text) => MenuItemFilters(
      menuCategoryId: menuCategoryId,
      search: text,
      minPrice: minPrice,
      maxPrice: maxPrice,
      saleOnly: saleOnly);
  MenuItemFilters withPriceRange(num? minimum, num? maximum) => MenuItemFilters(
      menuCategoryId: menuCategoryId,
      search: search,
      minPrice: minimum,
      maxPrice: maximum,
      saleOnly: saleOnly);
  MenuItemFilters withSaleOnly(bool value) => MenuItemFilters(
      menuCategoryId: menuCategoryId,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      saleOnly: value);

  bool get hasValidPrices =>
      (minPrice == null || (minPrice!.isFinite && minPrice! >= 0)) &&
      (maxPrice == null || (maxPrice!.isFinite && maxPrice! >= 0)) &&
      (minPrice == null || maxPrice == null || minPrice! <= maxPrice!);

  @override
  List<Object?> get props =>
      [menuCategoryId, search, minPrice, maxPrice, saleOnly];
}
