import '../../domain/entities/cart_mutation.dart';

/// The documented request fields shared by AddToCart and UpdateToCart.
///
/// UpdateToCart uses the option identifier, including an explicit null, as
/// part of the exact line identity. AddToCart keeps its existing omission
/// behavior for an unselected option.
class CartMutationRequestModel {
  CartMutationRequestModel({
    required this.menuItemId,
    required this.quantity,
    this.menuItemOptionId,
    required List<String> addonIds,
  }) : addonIds = List<String>.unmodifiable(addonIds);

  final String menuItemId;
  final int quantity;
  final String? menuItemOptionId;
  final List<String> addonIds;

  factory CartMutationRequestModel.fromDomain(CartMutation mutation) {
    final menuItemId = mutation.menuItemId.trim();
    final optionId = mutation.menuItemOptionId?.trim();
    if (menuItemId.isEmpty ||
        mutation.quantity < 0 ||
        mutation.addonIds.any((id) => id.trim().isEmpty)) {
      throw const FormatException('Invalid cart mutation request');
    }
    return CartMutationRequestModel(
      menuItemId: menuItemId,
      quantity: mutation.quantity,
      menuItemOptionId: optionId == null || optionId.isEmpty ? null : optionId,
      addonIds: mutation.addonIds
          .map((id) => id.trim())
          .toList(growable: false),
    );
  }

  /// Serializes the exact update identity when [preserveNullOptionId] is true.
  ///
  /// AddToCart historically omits an unselected option. UpdateToCart must not:
  /// `menuItemOptionId: null` distinguishes the no-option configuration from
  /// another selected variant of the same menu item.
  Map<String, Object?> toJson({bool preserveNullOptionId = false}) =>
      <String, Object?>{
        'menuItemId': menuItemId,
        'quantity': quantity,
        if (preserveNullOptionId || menuItemOptionId != null)
          'menuItemOptionId': menuItemOptionId,
        'addonIds': addonIds,
      };
}
