import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_count.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/cart_mutation.dart';
import '../../domain/usecases/add_to_cart_use_case.dart';
import '../../domain/usecases/clear_cart_use_case.dart';
import '../../domain/usecases/get_cart_count_use_case.dart';
import '../../domain/usecases/get_my_cart_use_case.dart';
import '../../domain/usecases/update_to_cart_use_case.dart';
import 'cart_state.dart';

enum CartMutationResult { success, busy, failed, synchronizationFailed }

/// API-backed cart coordinator.
///
/// A single instance is scoped to the authenticated shell. It serializes every
/// mutation and only renders full snapshots from GetMyCart and GetCount. This
/// prevents an older refresh from restoring data after an update or Clear.
class CartCubit extends Cubit<CartState> {
  CartCubit({
    required AddToCartUseCase addToCartUseCase,
    required UpdateToCartUseCase updateToCartUseCase,
    required ClearCartUseCase clearCartUseCase,
    required GetMyCartUseCase getMyCartUseCase,
    required GetCartCountUseCase getCartCountUseCase,
  })  : _addToCartUseCase = addToCartUseCase,
        _updateToCartUseCase = updateToCartUseCase,
        _clearCartUseCase = clearCartUseCase,
        _getMyCartUseCase = getMyCartUseCase,
        _getCartCountUseCase = getCartCountUseCase,
        super(const CartState.initial());

  final AddToCartUseCase _addToCartUseCase;
  final UpdateToCartUseCase _updateToCartUseCase;
  final ClearCartUseCase _clearCartUseCase;
  final GetMyCartUseCase _getMyCartUseCase;
  final GetCartCountUseCase _getCartCountUseCase;

  bool _isRefreshing = false;
  bool _isMutating = false;
  int _snapshotVersion = 0;
  _PendingCartSnapshot? _pendingRefreshSnapshot;

  Future<void> load() => refresh();

  /// Refreshes both authoritative endpoints. The cart is not considered loaded
  /// from a mutation response because that response contains only one line.
  Future<void> refresh() async {
    if (isClosed || _isRefreshing || _isMutating) return;
    _isRefreshing = true;
    try {
      await _fetchAuthoritative(showLoading: true);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<CartMutationResult> add({
    required String menuItemId,
    required int quantity,
    String? menuItemOptionId,
    List<String> addonIds = const <String>[],
  }) =>
      _mutate(() async {
        await _addToCartUseCase(
          CartMutation(
            menuItemId: menuItemId,
            quantity: quantity,
            menuItemOptionId: menuItemOptionId,
            addonIds: addonIds,
          ),
        );
      });

  /// Updates the exact response line configuration. The verified UpdateToCart
  /// contract removes that exact configuration when [quantity] is zero.
  Future<CartMutationResult> updateLineQuantity(CartLine line, int quantity) {
    if (quantity < 0 || line.isRemoved || !line.isAvailable) {
      return Future<CartMutationResult>.value(CartMutationResult.failed);
    }
    return _mutate(() async {
      await _updateToCartUseCase(
        CartMutation(
          menuItemId: line.menuItemId,
          quantity: quantity,
          menuItemOptionId: line.menuItemOptionId,
          addonIds:
              line.addons.map((addon) => addon.id).toList(growable: false),
        ),
      );
    });
  }

  /// Clears all cart lines using DELETE /api/Cart/Clear, then fetches both
  /// server snapshots. It never doubles as a single-line removal operation.
  Future<CartMutationResult> clearCart() => _mutate(_clearCartUseCase.call);

  Future<CartMutationResult> _mutate(Future<void> Function() action) async {
    if (isClosed || _isMutating) return CartMutationResult.busy;
    _isMutating = true;
    emit(state.copyWith(clearFailure: true, isMutating: true));
    try {
      await action();
    } on FailureException catch (error) {
      _restorePendingRefreshAfterFailedMutation();
      _emitMutationFailure(error.failure);
      return CartMutationResult.failed;
    } catch (error) {
      _restorePendingRefreshAfterFailedMutation();
      _emitMutationFailure(
        Failure(FailureCode.unknown, debugMessage: error.toString()),
      );
      return CartMutationResult.failed;
    }

    // Any refresh started before a mutation can now be stale, including one
    // that captured lines before Clear. Invalidate it before the replacement
    // snapshot starts.
    _snapshotVersion++;
    _pendingRefreshSnapshot = null;
    final synchronized = await _fetchAuthoritative(
      showLoading: false,
      allowDuringMutation: true,
    );
    if (isClosed) return CartMutationResult.busy;
    _isMutating = false;
    emit(state.copyWith(isMutating: false));
    return synchronized
        ? CartMutationResult.success
        : CartMutationResult.synchronizationFailed;
  }

  Future<bool> _fetchAuthoritative({
    required bool showLoading,
    bool allowDuringMutation = false,
  }) async {
    if (isClosed) return false;
    final version = _snapshotVersion;
    if (showLoading) {
      emit(
        state.copyWith(
          status: CartStatus.loading,
          clearFailure: true,
          isMutating: _isMutating,
        ),
      );
    }
    try {
      final values = await Future.wait<Object>(<Future<Object>>[
        _getMyCartUseCase(),
        _getCartCountUseCase(),
      ]);
      if (isClosed || version != _snapshotVersion) return false;
      final cart = values[0] as Cart;
      final count = values[1] as CartCount;
      if (_isMutating && !allowDuringMutation) {
        _pendingRefreshSnapshot = _PendingCartSnapshot(cart, count);
      } else {
        _emitSnapshot(cart, count);
      }
      return true;
    } on FailureException catch (error) {
      if (version == _snapshotVersion &&
          (!_isMutating || allowDuringMutation)) {
        _emitRefreshFailure(error.failure);
      }
      return false;
    } catch (error) {
      if (version == _snapshotVersion &&
          (!_isMutating || allowDuringMutation)) {
        _emitRefreshFailure(
          Failure(FailureCode.unknown, debugMessage: error.toString()),
        );
      }
      return false;
    }
  }

  void _restorePendingRefreshAfterFailedMutation() {
    _isMutating = false;
    final pending = _pendingRefreshSnapshot;
    _pendingRefreshSnapshot = null;
    if (pending != null && !isClosed) {
      _emitSnapshot(pending.cart, pending.count);
    }
  }

  void _emitSnapshot(Cart cart, CartCount count) {
    if (isClosed) return;
    emit(
      CartState(
        status: cart.isEmpty ? CartStatus.empty : CartStatus.populated,
        cart: cart,
        count: count,
        isMutating: _isMutating,
      ),
    );
  }

  void _emitMutationFailure(Failure failure) {
    _isMutating = false;
    if (isClosed) return;
    final recoveredStatus = state.isLoading
        ? switch (state.cart) {
            null => CartStatus.error,
            final cart when cart.isEmpty => CartStatus.empty,
            _ => CartStatus.populated,
          }
        : null;
    emit(
      state.copyWith(
        status: recoveredStatus,
        failure: failure,
        clearFailure: false,
        isMutating: false,
      ),
    );
  }

  void _emitRefreshFailure(Failure failure) {
    if (isClosed) return;
    emit(
      CartState(
        status: CartStatus.error,
        cart: state.cart,
        count: state.count,
        failure: failure,
        isMutating: _isMutating,
      ),
    );
  }
}

class _PendingCartSnapshot {
  const _PendingCartSnapshot(this.cart, this.count);

  final Cart cart;
  final CartCount count;
}
