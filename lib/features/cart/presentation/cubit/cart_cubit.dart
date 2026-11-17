import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_count.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/cart_mutation.dart';
import '../../domain/entities/cart_update_result.dart';
import '../../domain/usecases/add_to_cart_use_case.dart';
import '../../domain/usecases/clear_cart_use_case.dart';
import '../../domain/usecases/get_cart_count_use_case.dart';
import '../../domain/usecases/get_my_cart_use_case.dart';
import '../../domain/usecases/update_to_cart_use_case.dart';
import 'cart_state.dart';

enum CartMutationResult { success, busy, failed, synchronizationFailed }

/// Authenticated-shell Cart coordinator.
///
/// Mutations are serialized per exact line. Successful mutations update the
/// visible line from confirmed response/request data, then schedule one
/// authoritative Cart and badge refresh after active mutations settle.
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

  final Set<String> _activeLineKeys = <String>{};
  final Map<String, Future<CartMutationResult>> _lineMutationTasks =
      <String, Future<CartMutationResult>>{};
  final Map<String, int> _queuedQuantities = <String, int>{};
  final Map<String, int> _desiredQuantities = <String, int>{};
  final Map<String, int> _inFlightQuantities = <String, int>{};
  bool _isRefreshing = false;
  bool _isClearing = false;
  bool _isSynchronizing = false;
  bool _syncRequested = false;
  int _snapshotVersion = 0;
  Future<void>? _synchronizationTask;
  _PendingCartSnapshot? _pendingRefreshSnapshot;
  Failure? _pendingRefreshFailure;

  bool get _hasActiveMutations => _isClearing || _activeLineKeys.isNotEmpty;

  Future<void> load() => refresh();

  Future<void> refresh() async {
    if (isClosed ||
        _isRefreshing ||
        _hasActiveMutations ||
        _isSynchronizing) {
      return;
    }
    _isRefreshing = true;
    try {
      await _fetchAuthoritative(showLoading: true);
    } finally {
      _isRefreshing = false;
      if (_syncRequested) _requestSynchronization();
    }
  }

  Future<CartMutationResult> add({
    required String menuItemId,
    required int quantity,
    String? menuItemOptionId,
    List<String> addonIds = const <String>[],
  }) {
    final key = cartMutationKey(menuItemId, menuItemOptionId, addonIds);
    return _runSingleLineMutation(key, () async {
      final added = await _addToCartUseCase(
        CartMutation(
          menuItemId: menuItemId,
          quantity: quantity,
          menuItemOptionId: menuItemOptionId,
          addonIds: addonIds,
        ),
      );
      // AddToCart returns a complete server-priced line. Merge only when its
      // identity matches the request and a complete Cart snapshot is present.
      if (cartLineMutationKey(added) == key) {
        _mergeAddedLine(added, key);
      }
    });
  }

  /// Queues absolute targets for this exact line. Repeated taps replace a
  /// not-yet-sent target, while each sent request remains serialized.
  Future<CartMutationResult> updateLineQuantity(
    CartLine line,
    int quantity,
  ) {
    if (quantity < 0 || line.isRemoved || !line.isAvailable) {
      return Future<CartMutationResult>.value(CartMutationResult.failed);
    }
    if (isClosed || _isClearing) {
      return Future<CartMutationResult>.value(CartMutationResult.busy);
    }

    final key = cartLineMutationKey(line);
    final active = _lineMutationTasks[key];
    if (active != null) {
      if (_desiredQuantities[key] != quantity) {
        _desiredQuantities[key] = quantity;
        if (_inFlightQuantities[key] == quantity) {
          _queuedQuantities.remove(key);
        } else {
          _queuedQuantities[key] = quantity;
        }
      }
      return active;
    }
    if (_activeLineKeys.contains(key)) {
      return Future<CartMutationResult>.value(CartMutationResult.busy);
    }

    final completer = Completer<CartMutationResult>();
    _desiredQuantities[key] = quantity;
    _activeLineKeys.add(key);
    final task = completer.future;
    _lineMutationTasks[key] = task;
    _emitMutationState(clearFailure: true);
    unawaited(_processLineQuantityQueue(line, key, quantity, completer));
    return task;
  }

  /// Stepper actions use deltas so taps during a pending request accumulate
  /// from the latest requested quantity instead of repeating a stale target.
  Future<CartMutationResult> changeLineQuantityBy(CartLine line, int delta) {
    final key = cartLineMutationKey(line);
    final quantity = quantityAfterDelta(line, delta);
    if (quantity < 0) {
      return _lineMutationTasks[key] ??
          Future<CartMutationResult>.value(CartMutationResult.failed);
    }
    return updateLineQuantity(line, quantity);
  }

  int quantityAfterDelta(CartLine line, int delta) {
    final key = cartLineMutationKey(line);
    var baseQuantity = _desiredQuantities[key];
    if (baseQuantity == null) {
      for (final currentLine in state.items) {
        if (cartLineMutationKey(currentLine) == key) {
          baseQuantity = currentLine.quantity;
          break;
        }
      }
    }
    return (baseQuantity ?? line.quantity) + delta;
  }

  Future<CartMutationResult> clearCart() async {
    if (isClosed || _hasActiveMutations) return CartMutationResult.busy;
    _isClearing = true;
    _emitMutationState(clearFailure: true);
    try {
      await _clearCartUseCase();
    } on FailureException catch (error) {
      _isClearing = false;
      _restorePendingRefreshIfSafe();
      _emitMutationState();
      _emitMutationFailure(error.failure);
      return CartMutationResult.failed;
    } catch (error) {
      _isClearing = false;
      _restorePendingRefreshIfSafe();
      _emitMutationState();
      _emitMutationFailure(
        Failure(FailureCode.unknown, debugMessage: error.toString()),
      );
      return CartMutationResult.failed;
    }
    if (isClosed) return CartMutationResult.busy;

    _snapshotVersion++;
    _pendingRefreshSnapshot = null;
    _pendingRefreshFailure = null;
    final currentCart = state.cart ??
        Cart(items: const <CartLine>[], totalQuantity: 0, subTotal: 0);
    _isClearing = false;
    _emitLocalCart(currentCart.copyWith(items: const <CartLine>[]));
    _emitMutationState();
    _requestSynchronization();
    return CartMutationResult.success;
  }

  Future<CartMutationResult> _runSingleLineMutation(
    String key,
    Future<void> Function() action,
  ) async {
    if (isClosed || _isClearing || _activeLineKeys.contains(key)) {
      return CartMutationResult.busy;
    }
    _activeLineKeys.add(key);
    _emitMutationState(clearFailure: true);
    try {
      await action();
    } on FailureException catch (error) {
      _activeLineKeys.remove(key);
      _restorePendingRefreshIfSafe();
      _emitMutationState();
      _emitMutationFailure(error.failure);
      return CartMutationResult.failed;
    } catch (error) {
      _activeLineKeys.remove(key);
      _restorePendingRefreshIfSafe();
      _emitMutationState();
      _emitMutationFailure(
        Failure(FailureCode.unknown, debugMessage: error.toString()),
      );
      return CartMutationResult.failed;
    }
    if (isClosed) return CartMutationResult.busy;

    _snapshotVersion++;
    _pendingRefreshSnapshot = null;
    _pendingRefreshFailure = null;
    _activeLineKeys.remove(key);
    _emitMutationState();
    _requestSynchronization();
    return CartMutationResult.success;
  }

  Future<void> _processLineQuantityQueue(
    CartLine line,
    String key,
    int firstQuantity,
    Completer<CartMutationResult> completer,
  ) async {
    var quantity = firstQuantity;
    var didSucceed = false;
    var failure = const Failure(FailureCode.unknown);
    var failed = false;

    while (!isClosed) {
      _inFlightQuantities[key] = quantity;
      try {
        final result = await _updateToCartUseCase(
          CartMutation(
            menuItemId: line.menuItemId,
            quantity: quantity,
            menuItemOptionId: line.menuItemOptionId,
            addonIds:
                line.addons.map((addon) => addon.id).toList(growable: false),
          ),
        );
        if (isClosed) break;
        _applyUpdatedLine(line, quantity, result);
        didSucceed = true;
        _snapshotVersion++;
        _pendingRefreshSnapshot = null;
        _pendingRefreshFailure = null;
        final nextQuantity = _queuedQuantities.remove(key);
        if (nextQuantity == null) break;
        quantity = nextQuantity;
      } on FailureException catch (error) {
        failure = error.failure;
        failed = true;
        break;
      } catch (error) {
        failure = Failure(FailureCode.unknown, debugMessage: error.toString());
        failed = true;
        break;
      }
    }

    _queuedQuantities.remove(key);
    _desiredQuantities.remove(key);
    _inFlightQuantities.remove(key);
    _activeLineKeys.remove(key);
    _lineMutationTasks.remove(key);

    if (isClosed) {
      if (!completer.isCompleted) completer.complete(CartMutationResult.busy);
      return;
    }

    if (failed) {
      _restorePendingRefreshIfSafe();
      _emitMutationState();
      _emitMutationFailure(failure);
      completer.complete(CartMutationResult.failed);
      if (didSucceed) _requestSynchronization();
      return;
    }

    if (!didSucceed) {
      completer.complete(CartMutationResult.busy);
      return;
    }
    _emitMutationState();
    _requestSynchronization();
    completer.complete(CartMutationResult.success);
  }

  void _applyUpdatedLine(
    CartLine line,
    int quantity,
    CartUpdateResult result,
  ) {
    final cart = _cartForSuccessfulMutation();
    if (cart == null) return;
    final key = cartLineMutationKey(line);
    final index = cart.items.indexWhere(
      (item) => cartLineMutationKey(item) == key,
    );
    if (index < 0) return;

    final items = <CartLine>[...cart.items];
    if (quantity == 0) {
      if (result.isRemoved) items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: quantity);
    }
    _emitLocalCart(cart.copyWith(items: items));
  }

  void _mergeAddedLine(CartLine added, String key) {
    final cart = _cartForSuccessfulMutation();
    if (cart == null) return;
    final items = <CartLine>[...cart.items];
    final index = items.indexWhere(
      (item) => cartLineMutationKey(item) == key,
    );
    if (index < 0) {
      items.add(added);
    } else {
      items[index] = added;
    }
    _emitLocalCart(cart.copyWith(items: items));
  }

  Cart? _cartForSuccessfulMutation() {
    final currentCart = state.cart;
    if (currentCart != null) return currentCart;
    final pending = _pendingRefreshSnapshot;
    if (pending == null) return null;
    _emitSnapshot(pending.cart, pending.count);
    return state.cart;
  }

  void _emitLocalCart(Cart cart) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: cart.isEmpty ? CartStatus.empty : CartStatus.populated,
        cart: cart,
        clearFailure: true,
        isSynchronizationFailure: false,
      ),
    );
  }

  Future<bool> _fetchAuthoritative({required bool showLoading}) async {
    if (isClosed) return false;
    final version = _snapshotVersion;
    if (showLoading) {
      emit(
        state.copyWith(
          status: state.cart == null ? CartStatus.loading : state.status,
          clearFailure: true,
          isSynchronizationFailure: false,
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
      if (_hasActiveMutations) {
        _pendingRefreshSnapshot = _PendingCartSnapshot(cart, count);
        _pendingRefreshFailure = null;
      } else {
        _emitSnapshot(cart, count);
      }
      return true;
    } on FailureException catch (error) {
      if (version == _snapshotVersion) {
        if (_hasActiveMutations) {
          _pendingRefreshFailure = error.failure;
        } else {
          _emitRefreshFailure(error.failure);
        }
      }
      return false;
    } catch (error) {
      if (version == _snapshotVersion) {
        final failure =
            Failure(FailureCode.unknown, debugMessage: error.toString());
        if (_hasActiveMutations) {
          _pendingRefreshFailure = failure;
        } else {
          _emitRefreshFailure(failure);
        }
      }
      return false;
    }
  }

  void _requestSynchronization() {
    _syncRequested = true;
    if (isClosed ||
        _hasActiveMutations ||
        _isRefreshing ||
        _synchronizationTask != null) {
      return;
    }
    final task = _runSynchronizationQueue();
    _synchronizationTask = task;
    unawaited(task.whenComplete(() {
      if (identical(_synchronizationTask, task)) {
        _synchronizationTask = null;
      }
      if (_syncRequested) _requestSynchronization();
    }));
  }

  Future<void> _runSynchronizationQueue() async {
    while (_syncRequested && !isClosed) {
      if (_hasActiveMutations || _isRefreshing) return;
      _syncRequested = false;
      final version = _snapshotVersion;
      _isSynchronizing = true;
      emit(
        state.copyWith(
          isSynchronizing: true,
          clearFailure: true,
          isSynchronizationFailure: false,
        ),
      );
      await _fetchAuthoritative(showLoading: false);
      if (isClosed) return;
      if (version != _snapshotVersion) {
        _syncRequested = true;
        continue;
      }
      _isSynchronizing = false;
      emit(state.copyWith(isSynchronizing: false));
    }
  }

  void _restorePendingRefreshIfSafe() {
    if (_hasActiveMutations || isClosed) return;
    final pending = _pendingRefreshSnapshot;
    _pendingRefreshSnapshot = null;
    if (pending != null) _emitSnapshot(pending.cart, pending.count);
    final failure = _pendingRefreshFailure;
    _pendingRefreshFailure = null;
    if (failure != null) _emitRefreshFailure(failure);
  }

  void _emitSnapshot(Cart cart, CartCount count) {
    if (isClosed) return;
    emit(
      CartState(
        status: cart.isEmpty ? CartStatus.empty : CartStatus.populated,
        cart: cart,
        count: count,
        mutatingLineKeys: Set<String>.of(_activeLineKeys),
        isClearing: _isClearing,
        isSynchronizing: _isSynchronizing,
      ),
    );
  }

  void _emitMutationState({bool clearFailure = false}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        mutatingLineKeys: Set<String>.of(_activeLineKeys),
        isClearing: _isClearing,
        clearFailure: clearFailure,
        isSynchronizationFailure: clearFailure ? false : null,
      ),
    );
  }

  void _emitMutationFailure(Failure failure) {
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
        isSynchronizationFailure: false,
      ),
    );
  }

  void _emitRefreshFailure(Failure failure) {
    if (isClosed) return;
    if (state.cart != null) {
      emit(
        state.copyWith(
          status: state.isLoading
              ? state.cart!.isEmpty
                  ? CartStatus.empty
                  : CartStatus.populated
              : null,
          failure: failure,
          isSynchronizationFailure: true,
        ),
      );
      return;
    }
    emit(
      CartState(
        status: CartStatus.error,
        failure: failure,
        mutatingLineKeys: Set<String>.of(_activeLineKeys),
        isClearing: _isClearing,
        isSynchronizing: _isSynchronizing,
        isSynchronizationFailure: _isSynchronizing,
      ),
    );
  }
}

class _PendingCartSnapshot {
  const _PendingCartSnapshot(this.cart, this.count);

  final Cart cart;
  final CartCount count;
}
