import 'package:equatable/equatable.dart';

class MenuCategory extends Equatable {
  const MenuCategory(
      {required this.id,
      required this.storeId,
      required this.nameAr,
      required this.nameEn,
      required this.displayOrder,
      required this.isActive,
      required this.itemsCount,
      this.imageUrl});
  final String id;
  final String storeId;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;

  /// Category metadata, never an alternative to product results/paging.
  final int itemsCount;

  @override
  List<Object?> get props => [
        id,
        storeId,
        nameAr,
        nameEn,
        imageUrl,
        displayOrder,
        isActive,
        itemsCount
      ];
}
