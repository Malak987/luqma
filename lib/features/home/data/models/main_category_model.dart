import '../../domain/entities/home_category.dart';

/// The customer-facing MainCategory API contract, mapped to the existing
/// Home entity rather than introducing a second category type in the domain.
final class MainCategoryModel {
  const MainCategoryModel({
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

  factory MainCategoryModel.fromJson(Object? json) {
    if (json is! Map<Object?, Object?> ||
        json.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid MainCategory response');
    }

    final displayOrder = json['displayOrder'];
    final isActive = json['isActive'];
    if (displayOrder is! int) {
      throw const FormatException(
        'Missing or invalid required field: displayOrder',
      );
    }
    if (isActive is! bool) {
      throw const FormatException(
          'Missing or invalid required field: isActive');
    }

    // An icon may be absent, but the response must still contain its key.
    // Other required fields are never silently defaulted on malformed data.
    final iconUrl = json['iconUrl'];
    if (!json.containsKey('iconUrl') ||
        (iconUrl != null && iconUrl is! String)) {
      throw const FormatException('Missing or invalid required field: iconUrl');
    }

    return MainCategoryModel(
      id: _requiredString(json, 'id'),
      nameAr: _requiredString(json, 'nameAr'),
      nameEn: _requiredString(json, 'nameEn'),
      iconUrl: iconUrl is String ? iconUrl.trim() : null,
      displayOrder: displayOrder,
      isActive: isActive,
    );
  }

  HomeCategory toDomain() => HomeCategory(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        iconUrl: iconUrl,
        displayOrder: displayOrder,
        isActive: isActive,
      );
}

String _requiredString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid required field: $key');
  }
  return value.trim();
}
