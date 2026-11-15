import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/store.dart';
import '../../domain/entities/cart_line.dart';

/// In-memory cart. A cart belongs to exactly one store.
class CartState extends Equatable {
  CartState({this.store, List<CartLine> lines = const <CartLine>[]})
      : lines = List<CartLine>.unmodifiable(lines);

  final Store? store;
  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.fold<int>(0, (sum, line) => sum + line.quantity);

  num get total => lines.fold<num>(0, (sum, line) => sum + line.total);

  int quantityOf(String lineKey) {
    for (final line in lines) {
      if (line.key == lineKey) return line.quantity;
    }
    return 0;
  }

  @override
  List<Object?> get props => [store, lines];
}
