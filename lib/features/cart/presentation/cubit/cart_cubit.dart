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
/// Optimistic, server-reconciled model:
/// - The last GetMyCart/GetCount snapshots are kept privately as the
///   authoritative base. Everything the customer sees is rebuilt from that
///   base plus pending per-line overrides, so taps are reflected immediately
///   without waiting for the network.
/// - Same-line mutations are serialized per exact configuration; repeated
///   taps coalesce into the latest requested quantity (clamped to 1-99).
/// - Older responses never overwrite newer requested quantities.
/// - After confirmed mutations one authoritative refresh replaces the
///   optimistic projection; older refreshes cannot win (snapshot version
///   guard). GetCount is refreshed alongside GetMyCart because the badge is
///   served by GetCount in this app.
/// - Pending count deltas keep the cart badge honest while mutations are
///   in flight; a confirmed Clear shows an empty badge immediately.
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
  final Set<String> _activeAddKeys = <String>{};
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

  // ---------------------------------------------------------------
  // Optimistic layer. Never emitted directly; every emission goes through
  // _emitPendingDisplay/_emitSnapshot so the display always equals the
  // authoritative base with the pending overrides applied on top.
  // ---------------------------------------------------------------

  /// Last GetMyCart snapshot. Null until the first successful load/refresh.
  Cart? _authoritativeCart;

  /// Exact-configuration key -> replacement line, or null to hide the line
  /// (an optimistic removal pending confirmation/sync).
  final Map<String, CartLine?> _pendingLineOverrides = <String, CartLine?>{};

  /// AddToCart key -> server-priced line, merged into the display cart until
  /// the next authoritative snapshot drops it.
  final Map<String, CartLine> _pendingAddedLines = <String, CartLine>{};

  /// Update key -> quantity delta versus the last authoritative snapshot.
  final Map<String, int> _pendingLineDeltas = <String, int>{};

  /// Add key -> additive quantity delta. Kept separate from the absolute
  /// line deltas so an add of an existing configuration never clobbers it.
  final Map<String, int> _pendingAddDeltas = <String, int>{};

  /// Keys of lines confirmed removed (quantity 0 + isRemoved) by this batch.
  final Set<String> _confirmedRemovedKeys = <String>{};

  /// Confirmed replacement lines for the current batch, by key.
  final Map<String, CartLine> _confirmedLines = <String, CartLine>{};

  bool get _hasActiveMutations => _isClearing || _activeLineKeys.isNotEmpty;

  int get _pendingCountDelta =>
      _pendingLineDeltas.values.fold(0, (sum, delta) => sum + delta) +
      _pendingAddDeltas.values.fold(0, (sum, delta) => sum + delta);

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
    return _runSingleLineMutation(
      key,
      () async {
        final added = await _addToCartUseCase(
          CartMutation(
            menuItemId: menuItemId,
            quantity: quantity,
            menuItemOptionId: menuItemOptionId,
            addonIds: addonIds,
          ),
        );
        // AddToCart returns one server-priced line, never a cart snapshot.
        // Merge it only when its identity matches the request.
        if (cartLineMutationKey(added) == key) {
          _pendingAddedLines[key] = added;
        }
      },
      optimisticCountDelta: quantity,
    );
  }

  /// Queues absolute targets for this exact line. Repeated taps replace a
  /// not-yet-sent target, while each sent request remains serialized.
  ///
  /// Business rules enforced before any request is sent:
  /// - 0-99 only (0 removes this exact configuration; more is rejected).
  /// - Unavailable lines cannot be increased but can be decreased/removed.
  /// - Removed lines cannot be changed.
  Future<CartMutationResult> updateLineQuantity(
    CartLine line,
    int quantity,
  ) {
    if (quantity < 0 ||
        quantity > kMaxCartLineQuantity ||
        line.isRemoved ||
        (!line.isAvailable && quantity >= line.quantity)) {
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
        _applyOptimisticLine(key, quantity);
      }
      return active;
    }
    if (_activeLineKeys.contains(key)) {
      return Future<CartMutationResult>.value(CartMutationResult.busy);
    }
    // Nothing to do: the displayed quantity already matches the target and
    // no pending removal override hides it.
    final displayed = _displayLineByKey(key);
    if (displayed != null &&
        displayed.quantity == quantity &&
        !_pendingLineOverrides.containsKey(key)) {
      return Future<CartMutationResult>.value(CartMutationResult.success);
    }

    final completer = Completer<CartMutationResult>();
    _desiredQuantities[key] = quantity;
    _confirmedLines.remove(key);
    _confirmedRemovedKeys.remove(key);
    _activeLineKeys.add(key);
    final task = completer.future;
    _lineMutationTasks[key] = task;
    final baseLine = displayed ?? line;
    _applyOptimisticLine(key, quantity, fallbackLine: baseLine);
    unawaited(_processLineQuantityQueue(baseLine, key, quantity, completer));
    return task;
  }

  /// Stepper actions use deltas so taps during a pending request accumulate
  /// from the latest requested quantity instead of repeating a stale target.
  /// The accumulated target is clamped to the documented maximum of 99.
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
    final target = (baseQuantity ?? line.quantity) + delta;
    return target > kMaxCartLineQuantity ? kMaxCartLineQuantity : target;
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
    // Clear was confirmed: the cart is known to be empty, so content and
    // badge go to zero immediately instead of waiting for the sync.
    _authoritativeCart = Cart(
      items: const <CartLine>[],
      totalQuantity: 0,
      subTotal: 0,
    );
    _pendingLineOverrides.clear();
    _pendingAddedLines.clear();
    _pendingLineDeltas.clear();
    _pendingAddDeltas.clear();
    _confirmedLines.clear();
    _confirmedRemovedKeys.clear();
    _isClearing = false;
    _emitPendingDisplay(
      count: const CartCount(linesCount: 0, totalQuantity: 0),
    );
    _requestSynchronization();
    return CartMutationResult.success;
  }

  Future<CartMutationResult> _runSingleLineMutation(
    String key,
    Future<void> Function() action, {
    int optimisticCountDelta = 0,
  }) async {
    if (isClosed || _isClearing || _activeLineKeys.contains(key)) {
      return CartMutationResult.busy;
    }
    _activeLineKeys.add(key);
    if (optimisticCountDelta > 0) {
      _activeAddKeys.add(key);
      _pendingAddDeltas[key] = optimisticCountDelta;
    }
    _emitPendingDisplay();
    try {
      await action();
    } on FailureException catch (error) {
      _activeLineKeys.remove(key);
      if (optimisticCountDelta > 0) {
        _activeAddKeys.remove(key);
        _pendingAddDeltas.remove(key);
      }
      _restorePendingRefreshIfSafe();
      _emitPendingDisplay();
      _emitMutationFailure(error.failure);
      return CartMutationResult.failed;
    } catch (error) {
      _activeLineKeys.remove(key);
      if (optimisticCountDelta > 0) {
        _activeAddKeys.remove(key);
        _pendingAddDeltas.remove(key);
      }
      _restorePendingRefreshIfSafe();
      _emitPendingDisplay();
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
    if (optimisticCountDelta > 0) _activeAddKeys.remove(key);
    _emitPendingDisplay();
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

    // Final reconciliation of the optimistic projection for this batch.
    // Success: keep the last confirmed quantity projected. Failure: roll the
    // line back to the last confirmed state instead of the optimistic target.
    final int effectiveQuantity;
    if (_confirmedRemovedKeys.contains(key)) {
      _pendingLineOverrides[key] = null;
      effectiveQuantity = 0;
    } else if (_confirmedLines.containsKey(key)) {
      _pendingLineOverrides[key] = _confirmedLines[key];
      effectiveQuantity = _confirmedLines[key]!.quantity;
    } else if (failed) {
      // Nothing was confirmed: restore the pre-mutation line.
      _pendingLineOverrides[key] = line;
      effectiveQuantity = line.quantity;
    } else {
      effectiveQuantity = line.quantity;
    }
    _pendingLineDeltas[key] =
        effectiveQuantity - _authoritativeQuantityOf(key);

    if (failed) {
      _restorePendingRefreshIfSafe();
      _emitPendingDisplay();
      _emitMutationFailure(failure);
      completer.complete(CartMutationResult.failed);
      if (didSucceed) _requestSynchronization();
      return;
    }

    if (!didSucceed) {
      _emitPendingDisplay();
      completer.complete(CartMutationResult.busy);
      return;
    }
    _emitPendingDisplay();
    _requestSynchronization();
    completer.complete(CartMutationResult.success);
  }

  void _applyUpdatedLine(
    CartLine line,
    int quantity,
    CartUpdateResult result,
  ) {
    final key = cartLineMutationKey(line);
    if (quantity == 0 && result.isRemoved) {
      _confirmedRemovedKeys.add(key);
      _confirmedLines.remove(key);
    } else if (quantity == 0) {
      // The server did not confirm the removal: keep nothing optimistic and
      // let the authoritative snapshot drive the line again.
      _confirmedRemovedKeys.remove(key);
      _confirmedLines.remove(key);
      _pendingLineOverrides.remove(key);
      _pendingLineDeltas[key] = 0;
      _emitPendingDisplay();
      return;
    } else {
      _confirmedLines[key] = line.copyWith(quantity: quantity);
      _confirmedRemovedKeys.remove(key);
    }

    final desired = _desiredQuantities[key];
    if (_confirmedRemovedKeys.contains(key)) {
      _pendingLineOverrides[key] = null;
    } else {
      final target = desired ?? quantity;
      final base = _confirmedLines[key] ?? line;
      _pendingLineOverrides[key] =
          target == 0 ? null : base.copyWith(quantity: target);
    }
    final effective = _desiredQuantities[key] ?? quantity;
    _pendingLineDeltas[key] = effective - _authoritativeQuantityOf(key);
    _emitPendingDisplay();
  }

  void _applyOptimisticLine(
    String key,
    int target, {
    CartLine? fallbackLine,
  }) {
    final display = _displayLineByKey(key) ?? fallbackLine;
    if (target <= 0) {
      // Optimistic removal: hide the exact line until the server confirms.
      _pendingLineOverrides[key] = null;
    } else if (display != null) {
      _pendingLineOverrides[key] = display.copyWith(quantity: target);
    }
    _pendingLineDeltas[key] = target - _authoritativeQuantityOf(key);
    _emitPendingDisplay();
  }

  CartLine? _displayLineByKey(String key) {
    for (final item in state.items) {
      if (cartLineMutationKey(item) == key) return item;
    }
    return null;
  }

  int _authoritativeQuantityOf(String key) {
    final cart = _authoritativeCart;
    if (cart == null) return 0;
    var sum = 0;
    for (final item in cart.items) {
      if (cartLineMutationKey(item) == key) sum += item.quantity;
    }
    return sum;
  }

  Cart? _buildDisplayCart() {
    final base = _authoritativeCart;
    if (base == null) return null;
    final items = List<CartLine>.of(base.items);
    for (final added in _pendingAddedLines.values) {
      final addedKey = cartLineMutationKey(added);
      final index = items.indexWhere(
        (item) => cartLineMutationKey(item) == addedKey,
      );
      if (index >= 0) {
        items[index] = added;
      } else {
        items.add(added);
      }
    }
    for (final entry in _pendingLineOverrides.entries) {
      final index = items.indexWhere(
        (item) => cartLineMutationKey(item) == entry.key,
      );
      final replacement = entry.value;
      if (replacement == null) {
        if (index >= 0) items.removeAt(index);
      } else if (index >= 0) {
        // Keep the snapshot's server-priced fields; only the optimistic
        // quantity is projected from the pending override.
        items[index] = items[index].copyWith(quantity: replacement.quantity);
      } else {
        items.add(replacement);
      }
    }
    return base.copyWith(items: List<CartLine>.unmodifiable(items));
  }

  void _emitPendingDisplay({CartCount? count}) {
    if (isClosed) return;
    final display = _buildDisplayCart();
    emit(
      state.copyWith(
        status: display == null
            ? state.status
            : display.isEmpty
                ? CartStatus.empty
                : CartStatus.populated,
        cart: display,
        count: count,
        pendingCountDelta: _pendingCountDelta,
        mutatingLineKeys: Set<String>.of(_activeLineKeys),
        isClearing: _isClearing,
        isSynchronizing: _isSynchronizing,
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
          pendingCountDelta: _pendingCountDelta,
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
    _authoritativeCart = cart;
    // This snapshot reflects every mutation that completed before the fetch
    // started (guarded by _snapshotVersion), so bookkeeping for them goes.
    final stillPending = _activeLineKeys;
    _pendingAddedLines.removeWhere((key, _) => !_activeAddKeys.contains(key));
    _pendingLineOverrides.removeWhere((key, _) => !stillPending.contains(key));
    _pendingLineDeltas.removeWhere((key, _) => !stillPending.contains(key));
    _pendingAddDeltas.removeWhere((key, _) => !_activeAddKeys.contains(key));
    // Rebase in-flight edits: the snapshot includes their confirmed steps
    // but not the requested target the customer is still waiting on.
    for (final key in stillPending) {
      final desired = _desiredQuantities[key];
      if (desired != null) {
        _pendingLineDeltas[key] = desired - _authoritativeQuantityOf(key);
      }
    }
    final display = _buildDisplayCart();
    emit(
      CartState(
        status: display == null || display.isEmpty
            ? CartStatus.empty
            : CartStatus.populated,
        cart: display,
        count: count,
        mutatingLineKeys: Set<String>.of(_activeLineKeys),
        isClearing: _isClearing,
        isSynchronizing: _isSynchronizing,
        pendingCountDelta: _pendingCountDelta,
      ),
    );
  }

  void _emitMutationState({bool clearFailure = false}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        mutatingLineKeys: Set<String>.of(_activeLineKeys),
        isClearing: _isClearing,
        pendingCountDelta: _pendingCountDelta,
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
        pendingCountDelta: _pendingCountDelta,
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
          pendingCountDelta: _pendingCountDelta,
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
        pendingCountDelta: _pendingCountDelta,
      ),
    );
  }
}

class _PendingCartSnapshot {
  const _PendingCartSnapshot(this.cart, this.count);

  final Cart cart;
  final CartCount count;
}
