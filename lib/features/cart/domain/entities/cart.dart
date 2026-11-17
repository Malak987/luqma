import 'package:equatable/equatable.dart';

import 'cart_line.dart';

/// The authoritative GetMyCart snapshot.
class Cart extends Equatable {
  Cart({
    required List<CartLine> items,
    required this.totalQuantity,
    required this.subTotal,
  }) : items = List<CartLine>.unmodifiable(items);

  final List<CartLine> items;
  final int totalQuantity;
  final num subTotal;

  bool get isEmpty => items.isEmpty;

  Cart copyWith({List<CartLine>? items}) => Cart(
    items: items ?? this.items,
    totalQuantity: totalQuantity,
    subTotal: subTotal,
  );

  @override
  List<Object?> get props => <Object?>[items, totalQuantity, subTotal];
}
