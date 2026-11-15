import 'package:equatable/equatable.dart';

class StoreQuery extends Equatable {
  const StoreQuery({
    required this.mainCategoryId,
    required this.pageNumber,
    required this.pageSize,
    this.cuisineId,
    this.openNowOnly = false,
  });

  final String mainCategoryId;
  final String? cuisineId;
  final bool openNowOnly;
  final int pageNumber;
  final int pageSize;

  @override
  List<Object?> get props => [
        mainCategoryId,
        cuisineId,
        openNowOnly,
        pageNumber,
        pageSize,
      ];
}
