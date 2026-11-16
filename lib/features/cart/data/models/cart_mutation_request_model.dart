import '../../domain/entities/cart_mutation.dart';

/// The documented request fields shared by AddToCart and UpdateToCart.
///
/// No null option identifier is invented; an unavailable selected ID is
/// omitted until the backend's null-option contract is clarified.
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
        mutation.quantity <= 0 ||
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

  Map<String, Object> toJson() => <String, Object>{
    'menuItemId': menuItemId,
    'quantity': quantity,
    if (menuItemOptionId != null) 'menuItemOptionId': menuItemOptionId!,
    'addonIds': addonIds,
  };
}
