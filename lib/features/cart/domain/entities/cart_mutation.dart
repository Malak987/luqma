import 'package:equatable/equatable.dart';

/// Documented AddToCart/UpdateToCart input.
///
/// A null option ID represents the no-option configuration. UpdateToCart
/// preserves it explicitly so the API can target that exact cart line.
class CartMutation extends Equatable {
  CartMutation({
    required this.menuItemId,
    required this.quantity,
    this.menuItemOptionId,
    List<String> addonIds = const <String>[],
  }) : addonIds = List<String>.unmodifiable(addonIds);

  final String menuItemId;
  final int quantity;
  final String? menuItemOptionId;
  final List<String> addonIds;

  @override
  List<Object?> get props => <Object?>[
    menuItemId,
    quantity,
    menuItemOptionId,
    addonIds,
  ];
}
