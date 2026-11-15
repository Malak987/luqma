import 'package:equatable/equatable.dart';

class Cuisine extends Equatable {
  const Cuisine({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.displayOrder,
    required this.isActive,
    this.imageUrl,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;

  @override
  List<Object?> get props =>
      [id, nameAr, nameEn, imageUrl, displayOrder, isActive];
}
