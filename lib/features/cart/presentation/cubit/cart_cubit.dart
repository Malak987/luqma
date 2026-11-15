import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../catalog/domain/entities/menu_item.dart';
import '../../../catalog/domain/entities/store.dart';
import '../../domain/entities/cart_line.dart';
import 'cart_state.dart';

enum CartAddResult { added, otherStore }

/// Owns the local cart only. There is no cart/order API yet, so nothing here
/// touches the network; see BACKEND_MISSING_DATA.md.
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState());

  /// Adds [quantity] units (default one). Returns [CartAddResult.otherStore] (and changes nothing)
  /// when the cart already holds items from a different store.
  CartAddResult add({
    required Store store,
    required MenuItem item,
    String? optionId,
    Set<String> addonIds = const <String>{},
    int quantity = 1,
    String note = '',
  }) {
    final current = state.store;
    if (current != null &&
        !state.isEmpty &&
        current.id.toLowerCase() != store.id.toLowerCase()) {
      return CartAddResult.otherStore;
    }
    _append(store, item, optionId, addonIds, quantity, note);
    return CartAddResult.added;
  }

  /// Clears the cart and starts a new one from [store].
  void replaceWith({
    required Store store,
    required MenuItem item,
    String? optionId,
    Set<String> addonIds = const <String>{},
    int quantity = 1,
    String note = '',
  }) {
    if (isClosed) return;
    emit(CartState());
    _append(store, item, optionId, addonIds, quantity, note);
  }

  void increment(String lineKey) => _changeQuantity(lineKey, 1);

  void decrement(String lineKey) => _changeQuantity(lineKey, -1);

  void clear() {
    if (isClosed) return;
    emit(CartState());
  }

  void _append(
    Store store,
    MenuItem item,
    String? optionId,
    Set<String> addonIds,
    int quantity,
    String note,
  ) {
    if (isClosed) return;
    final units = quantity < 1 ? 1 : quantity;
    final cleanNote = note.trim();
    final key = CartLine.keyFor(item.id, optionId, addonIds, cleanNote);
    final lines = <CartLine>[...state.lines];
    final index = lines.indexWhere((line) => line.key == key);
    if (index >= 0) {
      lines[index] = lines[index].withQuantity(lines[index].quantity + units);
    } else {
      lines.add(CartLine(
        item: item,
        quantity: units,
        optionId: optionId,
        addonIds: addonIds,
        note: cleanNote,
      ));
    }
    emit(CartState(store: store, lines: lines));
  }

  void _changeQuantity(String lineKey, int delta) {
    if (isClosed) return;
    final lines = <CartLine>[...state.lines];
    final index = lines.indexWhere((line) => line.key == lineKey);
    if (index < 0) return;
    final next = lines[index].quantity + delta;
    if (next <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].withQuantity(next);
    }
    emit(lines.isEmpty
        ? CartState()
        : CartState(store: state.store, lines: lines));
  }
}
