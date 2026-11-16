import 'package:equatable/equatable.dart';

/// Documented AddToCart/UpdateToCart input.
///
/// The app does not synthesize a null option ID: it omits the field when no
/// selected ID is available. Backend null-option semantics remain unresolved.
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
