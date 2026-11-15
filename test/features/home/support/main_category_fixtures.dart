import 'dart:async';

import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/home/domain/repositories/main_category_repository.dart';

const mainCategoryId = '6f1c7b8e-1a2b-4c3d-8e4f-000000000001';
const mainCategoryTimestamp = '2026-11-14T00:45:18.593421Z';
const mainCategoryIconUrl =
    'https://luqma-api.runasp.net/icons/categories/restaurants.png';

Map<String, dynamic> mainCategoryJson({
  String id = mainCategoryId,
  String nameAr = 'مطاعم',
  String nameEn = 'Restaurants',
  String? iconUrl = mainCategoryIconUrl,
  int displayOrder = 1,
  bool isActive = true,
}) =>
    <String, dynamic>{
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'iconUrl': iconUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };

Map<String, dynamic> mainCategoryEnvelope({
  required Object? data,
  bool isSucceeded = true,
  String message = 'تم جلب الأصناف بنجاح',
}) =>
    <String, dynamic>{
      'message': message,
      'data': data,
      'isSucceeded': isSucceeded,
      'timestamp': mainCategoryTimestamp,
    };

HomeCategory homeCategory({
  String id = mainCategoryId,
  String nameAr = 'مطاعم',
  String nameEn = 'Restaurants',
  String? iconUrl,
  int displayOrder = 1,
  bool isActive = true,
}) =>
    HomeCategory(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      iconUrl: iconUrl,
      displayOrder: displayOrder,
      isActive: isActive,
    );

/// Handwritten fake, like the other feature tests. No HTTP or platform access.
class FakeMainCategoryRepository implements MainCategoryRepository {
  FakeMainCategoryRepository({
    this.categories = const <HomeCategory>[],
    this.exception,
    this.pendingResult,
  });

  List<HomeCategory> categories;
  Object? exception;
  Completer<List<HomeCategory>>? pendingResult;
  int calls = 0;

  @override
  Future<List<HomeCategory>> getAllMainCategories() async {
    calls++;
    final error = exception;
    if (error != null) throw error;
    return pendingResult == null ? categories : await pendingResult!.future;
  }
}
