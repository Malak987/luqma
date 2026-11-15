import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/menu_item.dart';
import '../services/cart_pricing.dart';

/// One distinct configuration of a menu item inside the cart.
class CartLine extends Equatable {
  CartLine({
    required this.item,
    required this.quantity,
    this.optionId,
    Set<String> addonIds = const <String>{},
    this.note = '',
  }) : addonIds = Set<String>.unmodifiable(addonIds);

  final MenuItem item;
  final int quantity;
  final String? optionId;
  final Set<String> addonIds;

  /// Free-text request for the kitchen (empty when none).
  final String note;

  /// Same item with the same option, addons and note is the same line.
  String get key => keyFor(item.id, optionId, addonIds, note);

  num get unitPrice => CartPricing.unitPrice(
        item: item,
        optionId: optionId,
        addonIds: addonIds,
      );

  num get total => unitPrice * quantity;

  CartLine withQuantity(int value) => CartLine(
        item: item,
        quantity: value,
        optionId: optionId,
        addonIds: addonIds,
        note: note,
      );

  static String keyFor(
    String itemId,
    String? optionId,
    Set<String> addonIds, [
    String note = '',
  ]) {
    final addons = addonIds.map((id) => id.toLowerCase()).toList()..sort();
    return '${itemId.toLowerCase()}|${optionId?.toLowerCase() ?? ''}|'
        '${addons.join(',')}|${note.trim().toLowerCase()}';
  }

  @override
  List<Object?> get props => [item, quantity, optionId, addonIds, note];
}
