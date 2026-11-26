import 'package:equatable/equatable.dart';

/// Maximum quantity for one exact cart configuration.
///
/// The backend contract bounds every AddToCart/UpdateToCart quantity to
/// 1-99 (0 only for UpdateToCart removal). Clients must never emit a request
/// above this bound; the Cubit also clamps coalesced stepper targets to it.
const int kMaxCartLineQuantity = 99;

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
