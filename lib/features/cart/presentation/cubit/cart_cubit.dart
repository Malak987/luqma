import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_line.dart';
import '../../domain/entities/cart_mutation.dart';
import '../../domain/usecases/add_to_cart_use_case.dart';
import '../../domain/usecases/clear_cart_use_case.dart';
import '../../domain/usecases/get_my_cart_use_case.dart';
import '../../domain/usecases/update_to_cart_use_case.dart';
import 'cart_state.dart';

/// `busy` means "nothing to report": the tap was merged into a change that is
/// already on its way, and that change's own future reports the outcome.
enum CartMutationResult { success, busy, failed }

/// Authenticated-shell cart coordinator.
///
/// The model is deliberately small:
///
/// * `_base` is the last *confirmed* cart: the latest GetMyCart snapshot with
///   every confirmed mutation folded in locally.
/// * `_jobs` holds one entry per cart line that has an unconfirmed change.
///   A job stores only the latest *target quantity*; repeated taps overwrite
///   it, so ten taps on "+" become one or two requests, not ten.
/// * What the customer sees is always `_base` + the targets in `_jobs`.
///   Totals are projected from the line's own price, so nothing flickers into
///   an "updating..." placeholder.
/// * Lines never block each other and nothing is globally locked.
/// * After a burst settles, ONE debounced GetMyCart reconciles prices and
///   availability with the server. Older responses never overwrite newer
///   local changes (version guard).
class CartCubit extends Cubit<CartState> {
  CartCubit({
    required AddToCartUseCase addToCartUseCase,
    required UpdateToCartUseCase updateToCartUseCase,
    required ClearCartUseCase clearCartUseCase,
    required GetMyCartUseCase getMyCartUseCase,
  })  : _addToCartUseCase = addToCartUseCase,
        _updateToCartUseCase = updateToCartUseCase,
        _clearCartUseCase = clearCartUseCase,
        _getMyCartUseCase = getMyCartUseCase,
        super(const CartState.initial());

  final AddToCartUseCase _addToCartUseCase;
  final UpdateToCartUseCase _updateToCartUseCase;
  final ClearCartUseCase _clearCartUseCase;
  final GetMyCartUseCase _getMyCartUseCase;

  /// Quiet period after the last settled change before the single reconcile.
  static const Duration reconcileDelay = Duration(milliseconds: 400);

  Cart? _base;
  final Map<String, _LineJob> _jobs = <String, _LineJob>{};
  bool _isClearing = false;
  bool _isSynchronizing = false;
  int _version = 0;
  Timer? _reconcileTimer;
  Future<void>? _fetchTask;

  /// When the cart was last known to match the server (a GetMyCart snapshot
  /// or a mutation the server confirmed). Lets a tab switch reuse it instead
  /// of showing a loading state again.
  DateTime? _lastSyncedAt;
  static const Duration freshFor = Duration(seconds: 20);

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  Future<void> load() => refresh();

  /// Loads the cart. While changes are pending it does nothing: those changes
  /// schedule their own reconcile when they settle. A cart that was confirmed
  /// a moment ago is reused (no request, no spinner) unless [force] is set,
  /// which pull-to-refresh and retry use.
  Future<void> refresh({bool force = false}) async {
    if (isClosed || _isClearing || _jobs.isNotEmpty) return;
    if (!force && _isFresh) return;
    await _fetchAuthoritative();
  }

  bool get _isFresh {
    final at = _lastSyncedAt;
    return _base != null &&
        at != null &&
        !state.isSynchronizationFailure &&
        !state.hasError &&
        DateTime.now().difference(at) < freshFor;
  }

  /// Adds [quantity] more of this exact configuration.
  Future<CartMutationResult> add({
    required String menuItemId,
    required int quantity,
    String? menuItemOptionId,
    List<String> addonIds = const <String>[],
  }) {
    if (isClosed || _isClearing) return _result(CartMutationResult.busy);
    if (menuItemId.trim().isEmpty ||
        quantity < 1 ||
        quantity > kMaxCartLineQuantity ||
        addonIds.any((id) => id.trim().isEmpty)) {
      return _result(CartMutationResult.failed);
    }
    final key = cartMutationKey(menuItemId, menuItemOptionId, addonIds);
    final current = _jobs[key]?.target ?? _confirmedQuantity(key);
    if (current >= kMaxCartLineQuantity) {
      return _result(CartMutationResult.failed);
    }
    final target = current + quantity > kMaxCartLineQuantity
        ? kMaxCartLineQuantity
        : current + quantity;
    return _setTarget(
      key,
      target,
      menuItemId: menuItemId,
      menuItemOptionId: menuItemOptionId,
      addonIds: addonIds,
    );
  }

  /// Sets this exact line to [quantity] (0 removes it).
  ///
  /// Rules enforced before anything is sent: 0-99 only; removed lines cannot
  /// change; unavailable lines can only go down.
  Future<CartMutationResult> updateLineQuantity(CartLine line, int quantity) {
    if (quantity < 0 ||
        quantity > kMaxCartLineQuantity ||
        line.isRemoved ||
        (!line.isAvailable && quantity >= line.quantity)) {
      return _result(CartMutationResult.failed);
    }
    if (isClosed || _isClearing) return _result(CartMutationResult.busy);
    return _setTarget(
      cartLineMutationKey(line),
      quantity,
      menuItemId: line.menuItemId,
      menuItemOptionId: line.menuItemOptionId,
      addonIds: line.addons.map((addon) => addon.id).toList(growable: false),
    );
  }

  /// Stepper helper: the delta is applied to the latest *requested* quantity,
  /// so fast taps accumulate instead of repeating a stale target.
  Future<CartMutationResult> changeLineQuantityBy(CartLine line, int delta) {
    final quantity = quantityAfterDelta(line, delta);
    if (quantity < 0) {
      // A second "-" tap after the line is already heading to 0 is merged,
      // not an error.
      return _result(
        _jobs.containsKey(cartLineMutationKey(line))
            ? CartMutationResult.busy
            : CartMutationResult.failed,
      );
    }
    return updateLineQuantity(line, quantity);
  }

  int quantityAfterDelta(CartLine line, int delta) {
    final key = cartLineMutationKey(line);
    final base = _jobs[key]?.target ?? line.quantity;
    final target = base + delta;
    return target > kMaxCartLineQuantity ? kMaxCartLineQuantity : target;
  }

  Future<CartMutationResult> clearCart() async {
    if (isClosed || _isClearing || _jobs.isNotEmpty) {
      return CartMutationResult.busy;
    }
    _isClearing = true;
    _version++;
    _reconcileTimer?.cancel();
    _publish(clearFailure: true);
    try {
      await _clearCartUseCase();
    } catch (error) {
      _isClearing = false;
      if (isClosed) return CartMutationResult.busy;
      _publish(failure: _failureOf(error));
      _scheduleReconcile();
      return CartMutationResult.failed;
    }
    if (isClosed) return CartMutationResult.busy;
    _isClearing = false;
    _version++;
    // Clear was confirmed, so the cart is known to be empty right now.
    _base = Cart(items: const <CartLine>[], totalQuantity: 0, subTotal: 0);
    _publish(clearFailure: true, syncFailure: false);
    _scheduleReconcile();
    return CartMutationResult.success;
  }

  // ---------------------------------------------------------------------
  // Per-line jobs
  // ---------------------------------------------------------------------

  Future<CartMutationResult> _setTarget(
    String key,
    int target, {
    required String menuItemId,
    required String? menuItemOptionId,
    required List<String> addonIds,
  }) {
    final running = _jobs[key];
    if (running != null) {
      // Merge into the change already on its way (latest target wins).
      if (running.target != target) {
        running.target = target;
        _publish();
      }
      return _result(CartMutationResult.busy);
    }
    if (_base != null && _confirmedQuantity(key) == target) {
      return _result(CartMutationResult.success);
    }
    final job = _LineJob(
      menuItemId: menuItemId,
      menuItemOptionId: menuItemOptionId,
      addonIds: List<String>.unmodifiable(addonIds),
      target: target,
    );
    _jobs[key] = job;
    _version++;
    _reconcileTimer?.cancel();
    _publish(clearFailure: true, syncFailure: false);
    unawaited(_runJob(key, job));
    return job.done.future;
  }

  Future<void> _runJob(String key, _LineJob job) async {
    Failure? failure;
    // True when the server's own answers fully explain the cart, so the extra
    // GetMyCart that normally follows a change is unnecessary.
    var serverConfirmed = true;
    try {
      await _ensureBase();
      while (!isClosed) {
        final target = job.target;
        final confirmed = _confirmedQuantity(key);
        if (target == confirmed) break;

        if (confirmed == 0) {
          // The line is not in the cart yet: AddToCart returns the one
          // server-priced line, never a snapshot.
          final added = await _addToCartUseCase(
            CartMutation(
              menuItemId: job.menuItemId,
              quantity: target,
              menuItemOptionId: job.menuItemOptionId,
              addonIds: job.addonIds,
            ),
          );
          if (isClosed) break;
          if (cartLineMutationKey(added) != key) {
            serverConfirmed = false; // reconcile decides
            break;
          }
          _base = _withLine(_base!, key, added);
        } else {
          final updated = await _updateToCartUseCase(
            CartMutation(
              menuItemId: job.menuItemId,
              quantity: target,
              menuItemOptionId: job.menuItemOptionId,
              addonIds: job.addonIds,
            ),
          );
          if (isClosed) break;
          // A removal the server did not confirm is left to the reconcile.
          if (target == 0 && !updated.isRemoved) {
            serverConfirmed = false;
            break;
          }
          _base = _withQuantity(_base!, key, target);
        }
        _publish();
      }
    } catch (error) {
      failure = _failureOf(error);
    }

    if (identical(_jobs[key], job)) _jobs.remove(key);
    if (isClosed) {
      job.done.complete(CartMutationResult.busy);
      return;
    }
    _version++;
    // On failure the display falls back to the confirmed base, which rolls
    // the optimistic change back; the reconcile then settles uncertain cases.
    _publish(failure: failure);
    if (failure == null && serverConfirmed && _jobs.isEmpty) {
      // Everything was confirmed by the server's own responses: no second
      // round trip, no "syncing" state.
      _lastSyncedAt = DateTime.now();
    } else {
      _scheduleReconcile();
    }
    job.done.complete(
      failure == null ? CartMutationResult.success : CartMutationResult.failed,
    );
  }

  // ---------------------------------------------------------------------
  // Server reconciliation
  // ---------------------------------------------------------------------

  void _scheduleReconcile() {
    if (isClosed) return;
    _reconcileTimer?.cancel();
    _reconcileTimer = Timer(reconcileDelay, () {
      if (isClosed || _isClearing || _jobs.isNotEmpty) return;
      unawaited(_fetchAuthoritative());
    });
  }

  Future<void> _ensureBase() async {
    if (_base != null) return;
    // The shell already started loading the cart; wait for that request
    // instead of sending a second identical one.
    final active = _fetchTask;
    if (active != null) {
      try {
        await active;
      } catch (_) {}
      if (_base != null) return;
    }
    final cart = await _getMyCartUseCase();
    if (!isClosed) _base ??= cart;
  }

  Future<void> _fetchAuthoritative() {
    final active = _fetchTask;
    if (active != null) return active;
    final task = _fetch();
    _fetchTask = task;
    return task.whenComplete(() {
      if (identical(_fetchTask, task)) _fetchTask = null;
    });
  }

  Future<void> _fetch() async {
    final version = _version;
    final background = _base != null;
    if (background) {
      // Reconciling a cart the customer can already see: nothing is blocked,
      // the quiet "syncing" copy reports it.
      _isSynchronizing = true;
      emit(state.copyWith(isSynchronizing: true));
    } else {
      emit(
        state.copyWith(
          status: CartStatus.loading,
          clearFailure: true,
          isSynchronizationFailure: false,
        ),
      );
    }
    try {
      final cart = await _getMyCartUseCase();
      if (isClosed) return;
      // A newer local change wins; its own settle schedules another reconcile.
      if (version != _version || _jobs.isNotEmpty || _isClearing) return;
      _base = cart;
      _lastSyncedAt = DateTime.now();
      _publish(clearFailure: true, syncFailure: false);
    } catch (error) {
      if (isClosed || version != _version) return;
      final failure = _failureOf(error);
      if (_base == null) {
        _isSynchronizing = false;
        emit(
          state.copyWith(
            status: CartStatus.error,
            failure: failure,
            isSynchronizing: false,
            isSynchronizationFailure: false,
          ),
        );
      } else {
        // Keep showing the cart; surface a retryable banner.
        _publish(failure: failure, syncFailure: true);
      }
    } finally {
      // Every exit path clears the flag, so a guarded or cancelled reconcile
      // can never leave the UI saying "syncing" forever.
      if (!isClosed && _isSynchronizing) {
        _isSynchronizing = false;
        if (state.isSynchronizing) {
          emit(state.copyWith(isSynchronizing: false));
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Projection
  // ---------------------------------------------------------------------

  int _confirmedQuantity(String key) {
    final cart = _base;
    if (cart == null) return 0;
    for (final line in cart.items) {
      if (cartLineMutationKey(line) == key) return line.quantity;
    }
    return 0;
  }

  /// Confirmed base + pending targets.
  Cart? _display() {
    final base = _base;
    if (base == null) return null;
    var cart = base;
    for (final entry in _jobs.entries) {
      cart = _withQuantity(cart, entry.key, entry.value.target);
    }
    return cart;
  }

  bool get _hasUnpricedLines => _jobs.entries.any(
    (entry) => entry.value.target > 0 && _confirmedQuantity(entry.key) == 0,
  );

  void _publish({
    Failure? failure,
    bool clearFailure = false,
    bool? syncFailure,
  }) {
    if (isClosed) return;
    final display = _display();
    emit(
      state.copyWith(
        status: display == null
            ? null
            : display.isEmpty
            ? CartStatus.empty
            : CartStatus.populated,
        cart: display,
        failure: failure,
        clearFailure: clearFailure,
        mutatingLineKeys: Set<String>.of(_jobs.keys),
        isClearing: _isClearing,
        isSynchronizing: _isSynchronizing,
        isSynchronizationFailure: syncFailure,
        hasUnpricedLines: _hasUnpricedLines,
      ),
    );
  }

  Failure _failureOf(Object error) => error is FailureException
      ? error.failure
      : Failure(FailureCode.unknown, debugMessage: error.toString());

  Future<CartMutationResult> _result(CartMutationResult value) =>
      Future<CartMutationResult>.value(value);

  @override
  Future<void> close() {
    _reconcileTimer?.cancel();
    return super.close();
  }
}

class _LineJob {
  _LineJob({
    required this.menuItemId,
    required this.menuItemOptionId,
    required this.addonIds,
    required this.target,
  });

  final String menuItemId;
  final String? menuItemOptionId;
  final List<String> addonIds;

  /// Latest requested absolute quantity for this exact line.
  int target;

  final Completer<CartMutationResult> done = Completer<CartMutationResult>();
}

// -----------------------------------------------------------------------
// Pure cart arithmetic (no state, easy to unit-test)
// -----------------------------------------------------------------------

num _round2(num value) => (value * 100).round() / 100;

/// Returns [cart] with the line [key] set to [quantity] (0 removes it),
/// projecting the line total from the line's own price.
///
/// A line that is not in the cart yet cannot be priced client-side, so it is
/// only reflected in the total quantity (the badge).
Cart _withQuantity(Cart cart, String key, int quantity) {
  final index = cart.items.indexWhere(
    (line) => cartLineMutationKey(line) == key,
  );
  if (index < 0) {
    return quantity <= 0
        ? cart
        : cart.copyWith(totalQuantity: cart.totalQuantity + quantity);
  }
  final old = cart.items[index];
  if (quantity == old.quantity) return cart;
  final items = List<CartLine>.of(cart.items);
  final num newLineTotal;
  if (quantity <= 0) {
    items.removeAt(index);
    newLineTotal = 0;
  } else {
    final unit = old.quantity > 0
        ? old.lineTotal / old.quantity
        : old.unitPrice;
    newLineTotal = _round2(unit * quantity);
    items[index] = old.copyWith(quantity: quantity, lineTotal: newLineTotal);
  }
  final totalQuantity = cart.totalQuantity + (quantity - old.quantity);
  final subTotal = _round2(cart.subTotal + (newLineTotal - old.lineTotal));
  return cart.copyWith(
    items: items,
    totalQuantity: totalQuantity < 0 ? 0 : totalQuantity,
    subTotal: subTotal < 0 ? 0 : subTotal,
  );
}

/// Inserts or replaces the server-priced [line] and adjusts the totals.
Cart _withLine(Cart cart, String key, CartLine line) {
  final index = cart.items.indexWhere(
    (item) => cartLineMutationKey(item) == key,
  );
  final items = List<CartLine>.of(cart.items);
  final int oldQuantity;
  final num oldTotal;
  if (index >= 0) {
    oldQuantity = items[index].quantity;
    oldTotal = items[index].lineTotal;
    items[index] = line;
  } else {
    oldQuantity = 0;
    oldTotal = 0;
    items.add(line);
  }
  return cart.copyWith(
    items: items,
    totalQuantity: cart.totalQuantity + (line.quantity - oldQuantity),
    subTotal: _round2(cart.subTotal + (line.lineTotal - oldTotal)),
  );
}
