import 'package:equatable/equatable.dart';

/// Localized cuisine names embedded in a Store response.
///
/// Store cuisine entries intentionally keep only the fields that the Store API
/// supplies for card presentation. They are not assumed to be interchangeable
/// with the separately fetched Cuisine filter records.
class StoreCuisine extends Equatable {
  const StoreCuisine({this.nameAr, this.nameEn});

  final String? nameAr;
  final String? nameEn;

  /// Uses the current locale when it is present, then the other API-provided
  /// locale. This prevents a blank cuisine line without inventing text.
  String? localizedName(bool arabic) {
    final preferred = arabic ? nameAr : nameEn;
    final fallback = arabic ? nameEn : nameAr;
    return preferred ?? fallback;
  }

  @override
  List<Object?> get props => <Object?>[nameAr, nameEn];
}
