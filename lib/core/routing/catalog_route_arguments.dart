import '../../features/catalog/domain/entities/store.dart';
import '../../features/catalog/domain/queries/catalog_identifiers.dart';

class StoreDiscoveryArguments {
  const StoreDiscoveryArguments({
    required this.mainCategoryId,
    required this.nameAr,
    required this.nameEn,
  });
  final String mainCategoryId;
  final String nameAr;
  final String nameEn;

  bool get isValid =>
      isCatalogId(mainCategoryId) &&
      nameAr.trim().isNotEmpty &&
      nameEn.trim().isNotEmpty;
}

class StoreDetailsArguments {
  const StoreDetailsArguments({required this.store});
  final Store store;
  String get storeId => store.id;

  bool get isValid =>
      isCatalogId(store.id) &&
      isCatalogId(store.mainCategoryId) &&
      store.nameAr.trim().isNotEmpty &&
      store.nameEn.trim().isNotEmpty;
}
