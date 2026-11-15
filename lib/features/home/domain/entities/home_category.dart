import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One main category returned by the catalog API. Both names are retained so
/// changing the application's locale never requires another API request.
@immutable
class HomeCategory extends Equatable {
  const HomeCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.iconUrl,
    required this.displayOrder,
    required this.isActive,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String? iconUrl;
  final int displayOrder;
  final bool isActive;

  @override
  List<Object?> get props => <Object?>[
        id,
        nameAr,
        nameEn,
        iconUrl,
        displayOrder,
        isActive,
      ];
}
