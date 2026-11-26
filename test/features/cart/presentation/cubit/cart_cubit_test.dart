import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/cart/domain/entities/cart.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_line.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_update_result.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_cart_count_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_state.dart';

import '../../support/cart_fixtures.dart';

void main() {
  late FakeCartRepository repository;
  late CartCubit cubit;

  setUp(() {
    repository = FakeCartRepository();
    cubit = CartCubit(
      addToCartUseCase: AddToCartUseCase(repository),
      updateToCartUseCase: UpdateToCartUseCase(repository),
      clearCartUseCase: ClearCartUseCase(repository),
      getMyCartUseCase: GetMyCartUseCase(repository),
      getCartCountUseCase: GetCartCountUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  Future<void> waitForBackgroundSynchronization() async {
    if (!cubit.state.isSynchronizing) return;
    await cubit.stream.firstWhere((state) => !state.isSynchronizing);
  }

  test(
    'load uses GetMyCart and GetCount snapshots for content and badge',
    () async {
      repository
        ..currentCart = cart(items: <CartLine>[cartLine(quantity: 2)])
        ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
      await cubit.load();
      expect(cubit.state.status, CartStatus.populated);
      expect(cubit.state.items.single.id, cartLineId);
      expect(cubit.state.subTotal, 540);
      expect(cubit.state.badgeQuantity, 2);
    },
  );

  test('badge uses the authoritative GetCount totalQuantity', () async {
    repository
      ..currentCart = Cart(
        items: <CartLine>[cartLine(quantity: 2)],
        totalQuantity: 99,
        subTotal: 540,
      )
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
    await cubit.load();
    expect(cubit.state.badgeQuantity, 2);
    expect(cubit.state.totalQuantity, 2);
  });

  test(
    'add parses its line response but refreshes full cart and count',
    () async {
      repository
        ..currentCart = cart(items: <CartLine>[cartLine(quantity: 3)])
        ..currentCount = cartCount(linesCount: 1, totalQuantity: 3);
      final result = await cubit.add(
        menuItemId: cartMenuItemId,
        quantity: 3,
        menuItemOptionId: cartOptionId,
        addonIds: const <String>[cartAddonId],
      );
      await waitForBackgroundSynchronization();
      expect(result, CartMutationResult.success);
      expect(repository.lastAdd?.menuItemId, cartMenuItemId);
      expect(cubit.state.items.single.quantity, 3);
      expect(cubit.state.badgeQuantity, 3);
    },
  );

  test('confirmed quantity-zero removes the exact line before sync completes',
      () async {
    final removedLine = cartLine(quantity: 1, addons: <CartLineAddon>[
      const CartLineAddon(
        id: cartAddonId,
        nameAr: 'إضافة أرز',
        nameEn: 'Extra Rice',
        price: 20,
      ),
    ]);
    final retainedLine = cartLine(
      id: otherCartLineId,
      menuItemOptionId: otherCartOptionId,
      quantity: 2,
    );
    final syncCart = Completer<Cart>();
    final syncStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[removedLine, retainedLine])
      ..currentCount = cartCount(linesCount: 2, totalQuantity: 3);
    await cubit.load();
    repository
      ..currentUpdateResult = const CartUpdateResult(isRemoved: true)
      ..onGetMyCart = () {
        syncStarted.complete();
        return syncCart.future;
      };

    final mutation = cubit.updateLineQuantity(removedLine, 0);
    expect(await mutation, CartMutationResult.success);
    await syncStarted.future;

    expect(cubit.state.items, <CartLine>[retainedLine]);
    expect(cubit.state.isSynchronizing, isTrue);
    syncCart.complete(cart(items: <CartLine>[retainedLine]));
    await waitForBackgroundSynchronization();
    expect(cubit.state.items, <CartLine>[retainedLine]);
  });

  test('successful quantity update is visible while sync is pending', () async {
    final line = cartLine(quantity: 2);
    final syncCart = Completer<Cart>();
    final syncStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
    await cubit.load();
    repository.onGetMyCart = () {
      syncStarted.complete();
      return syncCart.future;
    };

    expect(
      await cubit.updateLineQuantity(line, 3),
      CartMutationResult.success,
    );
    await syncStarted.future;

    expect(cubit.state.items.single.quantity, 3);
    expect(cubit.state.items.single.lineTotal, line.lineTotal);
    expect(cubit.state.subTotal, line.lineTotal);
    expect(cubit.state.isSynchronizing, isTrue);
    syncCart.complete(
      cart(items: <CartLine>[cartLine(quantity: 3)]),
    );
    await waitForBackgroundSynchronization();
    expect(cubit.state.items.single.quantity, 3);
  });

  test('sync failure keeps the successful local quantity and reports sync error',
      () async {
    final line = cartLine(quantity: 2);
    final syncCart = Completer<Cart>();
    final syncStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
    await cubit.load();
    repository.onGetMyCart = () {
      syncStarted.complete();
      return syncCart.future;
    };

    final result = await cubit.updateLineQuantity(line, 3);
    await syncStarted.future;
    expect(result, CartMutationResult.success);
    expect(cubit.state.items.single.quantity, 3);
    expect(cubit.state.isSynchronizing, isTrue);

    syncCart.completeError(
      const FailureException(Failure(FailureCode.network)),
    );
    await waitForBackgroundSynchronization();

    expect(cubit.state.status, CartStatus.populated);
    expect(cubit.state.items.single.quantity, 3);
    expect(cubit.state.isSynchronizationFailure, isTrue);
    expect(cubit.state.failure?.code, FailureCode.network);
  });

  test('new add merges its confirmed line into an existing Cart immediately',
      () async {
    final existingLine = cartLine(quantity: 1);
    final addedLine = cartLine(
      id: otherCartLineId,
      menuItemOptionId: otherCartOptionId,
      quantity: 2,
    );
    final syncCart = Completer<Cart>();
    final syncStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[existingLine])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 1)
      ..currentLine = addedLine;
    await cubit.load();
    repository.onGetMyCart = () {
      syncStarted.complete();
      return syncCart.future;
    };

    expect(
      await cubit.add(
        menuItemId: cartMenuItemId,
        quantity: 2,
        menuItemOptionId: otherCartOptionId,
      ),
      CartMutationResult.success,
    );
    await syncStarted.future;

    expect(cubit.state.items, <CartLine>[existingLine, addedLine]);
    expect(cubit.state.subTotal, existingLine.lineTotal);
    syncCart.complete(cart(items: <CartLine>[existingLine, addedLine]));
    await waitForBackgroundSynchronization();
  });

  test('background sync does not block a mutation on another line', () async {
    final firstLine = cartLine(quantity: 1);
    final secondLine = cartLine(
      id: otherCartLineId,
      menuItemOptionId: otherCartOptionId,
      quantity: 2,
    );
    final pendingSync = Completer<Cart>();
    final syncStarted = Completer<void>();
    var cartReads = 0;
    repository
      ..currentCart = cart(items: <CartLine>[firstLine, secondLine])
      ..currentCount = cartCount(linesCount: 2, totalQuantity: 3);
    await cubit.load();
    repository.onGetMyCart = () {
      cartReads++;
      if (cartReads == 1) {
        syncStarted.complete();
        return pendingSync.future;
      }
      return Future<Cart>.value(repository.currentCart);
    };

    expect(
      await cubit.updateLineQuantity(firstLine, 2),
      CartMutationResult.success,
    );
    await syncStarted.future;
    repository
      ..currentCart = cart(
        items: <CartLine>[
          cartLine(quantity: 2),
          secondLine.copyWith(quantity: 3),
        ],
      )
      ..currentCount = cartCount(linesCount: 2, totalQuantity: 5);

    expect(
      await cubit.updateLineQuantity(secondLine, 3),
      CartMutationResult.success,
    );
    expect(cubit.state.items.map((line) => line.quantity).toList(), <int>[2, 3]);

    pendingSync.complete(repository.currentCart);
    await waitForBackgroundSynchronization();
    expect(cubit.state.items.map((line) => line.quantity).toList(), <int>[2, 3]);
    expect(cubit.state.badgeQuantity, 5);
  });

  test('different exact Cart lines can mutate independently', () async {
    final firstLine = cartLine(quantity: 1);
    final secondLine = cartLine(
      id: otherCartLineId,
      menuItemOptionId: otherCartOptionId,
      addons: const <CartLineAddon>[
        CartLineAddon(
          id: otherCartAddonId,
          nameAr: 'إضافة أخرى',
          nameEn: 'Other add-on',
          price: 15,
        ),
      ],
      quantity: 2,
    );
    final firstUpdate = Completer<CartUpdateResult>();
    final secondUpdate = Completer<CartUpdateResult>();
    final firstStarted = Completer<void>();
    final secondStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[firstLine, secondLine])
      ..currentCount = cartCount(linesCount: 2, totalQuantity: 3);
    await cubit.load();
    repository.onUpdate = (mutation) {
      if (mutation.menuItemOptionId == cartOptionId) {
        firstStarted.complete();
        return firstUpdate.future;
      }
      secondStarted.complete();
      return secondUpdate.future;
    };

    final first = cubit.updateLineQuantity(firstLine, 2);
    final second = cubit.updateLineQuantity(secondLine, 3);
    await Future.wait<void>(<Future<void>>[
      firstStarted.future,
      secondStarted.future,
    ]);
    expect(cubit.state.isLineMutating(firstLine), isTrue);
    expect(cubit.state.isLineMutating(secondLine), isTrue);

    firstUpdate.complete(const CartUpdateResult(isRemoved: false));
    expect(await first, CartMutationResult.success);
    expect(cubit.state.isLineMutating(firstLine), isFalse);
    expect(cubit.state.isLineMutating(secondLine), isTrue);

    repository.currentCart = cart(
      items: <CartLine>[
        firstLine.copyWith(quantity: 2),
        secondLine.copyWith(quantity: 3),
      ],
    );
    secondUpdate.complete(const CartUpdateResult(isRemoved: false));
    expect(await second, CartMutationResult.success);
    await waitForBackgroundSynchronization();
    expect(cubit.state.isMutating, isFalse);
  });

  test('rapid changes on the same exact line serialize latest quantity',
      () async {
    final line = cartLine(quantity: 2);
    final firstUpdate = Completer<CartUpdateResult>();
    final secondUpdate = Completer<CartUpdateResult>();
    final firstStarted = Completer<void>();
    final secondStarted = Completer<void>();
    final sentQuantities = <int>[];
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
    await cubit.load();
    repository.onUpdate = (mutation) {
      sentQuantities.add(mutation.quantity);
      if (sentQuantities.length == 1) {
        firstStarted.complete();
        return firstUpdate.future;
      }
      secondStarted.complete();
      return secondUpdate.future;
    };

    final first = cubit.changeLineQuantityBy(line, 1);
    await firstStarted.future;
    final repeatedTap = cubit.changeLineQuantityBy(line, 1);
    expect(cubit.state.isLineMutating(line), isTrue);
    firstUpdate.complete(const CartUpdateResult(isRemoved: false));
    await secondStarted.future;
    expect(sentQuantities, <int>[3, 4]);
    // Optimistic UI: the visible quantity tracks the latest requested
    // quantity, never an older server confirmation.
    expect(cubit.state.items.single.quantity, 4);

    repository
      ..currentCart = cart(items: <CartLine>[line.copyWith(quantity: 4)])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 4);
    secondUpdate.complete(const CartUpdateResult(isRemoved: false));
    expect(await first, CartMutationResult.success);
    expect(await repeatedTap, CartMutationResult.success);
    expect(cubit.state.items.single.quantity, 4);
    await waitForBackgroundSynchronization();
  });

  test('Clear Cart is rejected while a line mutation is in flight', () async {
    final line = cartLine(quantity: 2);
    final pendingUpdate = Completer<CartUpdateResult>();
    final updateStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
    await cubit.load();
    repository.onUpdate = (_) {
      updateStarted.complete();
      return pendingUpdate.future;
    };

    final update = cubit.updateLineQuantity(line, 3);
    await updateStarted.future;
    expect(await cubit.clearCart(), CartMutationResult.busy);
    expect(repository.clearCalls, 0);

    repository.currentCart = cart(items: <CartLine>[line.copyWith(quantity: 3)]);
    pendingUpdate.complete(const CartUpdateResult(isRemoved: false));
    expect(await update, CartMutationResult.success);
    await waitForBackgroundSynchronization();
    expect(cubit.state.items.single.quantity, 3);
  });

  test('line mutations are rejected while Clear Cart is in flight', () async {
    final line = cartLine(quantity: 2);
    final pendingClear = Completer<void>();
    final clearStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2)
      ..onClear = () {
        clearStarted.complete();
        return pendingClear.future;
      };
    await cubit.load();

    final clear = cubit.clearCart();
    await clearStarted.future;
    expect(cubit.state.isClearing, isTrue);
    expect(await cubit.updateLineQuantity(line, 1), CartMutationResult.busy);

    repository
      ..currentCart = cart()
      ..currentCount = cartCount();
    pendingClear.complete();
    expect(await clear, CartMutationResult.success);
    await waitForBackgroundSynchronization();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.isClearing, isFalse);
  });

  test('decrement from two to one sends the updated positive quantity',
      () async {
    final line = cartLine(quantity: 2);
    repository
      ..currentCart = cart(items: <CartLine>[cartLine(quantity: 1)])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 1);

    expect(
      await cubit.updateLineQuantity(line, 1),
      CartMutationResult.success,
    );
    await waitForBackgroundSynchronization();

    expect(repository.lastUpdate?.menuItemId, cartMenuItemId);
    expect(repository.lastUpdate?.quantity, 1);
    expect(repository.lastUpdate?.menuItemOptionId, cartOptionId);
    expect(repository.lastUpdate?.addonIds, isEmpty);
    expect(cubit.state.items.single.quantity, 1);
    expect(cubit.state.badgeQuantity, 1);
  });

  test(
    'decrement from one to zero removes only the exact option and add-on line after authoritative sync',
    () async {
      const selectedAddon = CartLineAddon(
        id: cartAddonId,
        nameAr: 'إضافة أرز',
        nameEn: 'Extra Rice',
        price: 20,
      );
      const retainedAddon = CartLineAddon(
        id: otherCartAddonId,
        nameAr: 'إضافة أخرى',
        nameEn: 'Other add-on',
        price: 15,
      );
      final removedLine = cartLine(
        quantity: 1,
        addons: const <CartLineAddon>[selectedAddon],
      );
      final retainedLine = cartLine(
        id: otherCartLineId,
        menuItemOptionId: otherCartOptionId,
        addons: const <CartLineAddon>[retainedAddon],
        quantity: 2,
      );
      repository
        ..currentUpdateResult = const CartUpdateResult(isRemoved: true)
        ..currentCart = cart(items: <CartLine>[retainedLine])
        ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);

      expect(
        await cubit.updateLineQuantity(removedLine, 0),
        CartMutationResult.success,
      );
      await waitForBackgroundSynchronization();

      expect(repository.lastUpdate?.menuItemId, cartMenuItemId);
      expect(repository.lastUpdate?.quantity, 0);
      expect(repository.lastUpdate?.menuItemOptionId, cartOptionId);
      expect(repository.lastUpdate?.addonIds, <String>[cartAddonId]);
      expect(repository.getMyCartCalls, 1);
      expect(repository.getCountCalls, 1);
      expect(cubit.state.items, <CartLine>[retainedLine]);
      expect(cubit.state.count?.linesCount, 1);
      expect(cubit.state.badgeQuantity, 2);
    },
  );

  test('zero removal preserves null option and empty add-on identity', () async {
    final line = cartLine(menuItemOptionId: null, quantity: 1);
    repository
      ..currentCart = cart()
      ..currentCount = cartCount()
      ..currentUpdateResult = const CartUpdateResult(isRemoved: true);

    expect(
      await cubit.updateLineQuantity(line, 0),
      CartMutationResult.success,
    );
    await waitForBackgroundSynchronization();
    expect(repository.lastUpdate?.menuItemId, cartMenuItemId);
    expect(repository.lastUpdate?.quantity, 0);
    expect(repository.lastUpdate?.menuItemOptionId, isNull);
    expect(repository.lastUpdate?.addonIds, isEmpty);
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.badgeQuantity, 0);
  });

  test('failed zero removal preserves the displayed line and badge', () async {
    final line = cartLine(quantity: 1);
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 1);
    await cubit.load();
    repository.onUpdate = (_) async => throw const FailureException(
          Failure(FailureCode.network),
        );

    expect(
      await cubit.updateLineQuantity(line, 0),
      CartMutationResult.failed,
    );
    expect(cubit.state.items, <CartLine>[line]);
    expect(cubit.state.badgeQuantity, 1);
    expect(cubit.state.failure?.code, FailureCode.network);
  });

  test('rapid repeated zero decrements are coalesced', () async {
    final gate = Completer<CartUpdateResult>();
    final line = cartLine(quantity: 1);
    var updateCalls = 0;
    repository
      ..currentCart = cart()
      ..currentCount = cartCount()
      ..onUpdate = (_) {
        updateCalls++;
        return gate.future;
      };

    final first = cubit.updateLineQuantity(line, 0);
    final second = cubit.updateLineQuantity(line, 0);
    gate.complete(const CartUpdateResult(isRemoved: true));
    expect(await first, CartMutationResult.success);
    expect(await second, CartMutationResult.success);
    await waitForBackgroundSynchronization();
    expect(updateCalls, 1);
    expect(repository.lastUpdate?.quantity, 0);
  });

  test('older refresh cannot restore a removed line after zero update',
      () async {
    final oldCart = Completer<Cart>();
    var cartReads = 0;
    repository
      ..currentCart = cart()
      ..currentCount = cartCount()
      ..currentUpdateResult = const CartUpdateResult(isRemoved: true)
      ..onGetMyCart = () {
        cartReads++;
        return cartReads == 1
            ? oldCart.future
            : Future<Cart>.value(repository.currentCart);
      };

    final olderRefresh = cubit.refresh();
    expect(
      await cubit.updateLineQuantity(cartLine(quantity: 1), 0),
      CartMutationResult.success,
    );
    oldCart.complete(cart(items: <CartLine>[cartLine(quantity: 1)]));
    await olderRefresh;
    await waitForBackgroundSynchronization();

    expect(cubit.state.status, CartStatus.empty);
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.badgeQuantity, 0);
  });

  test('Clear sends one request then replaces content and badge from snapshots',
      () async {
    repository
      ..currentCart = cart()
      ..currentCount = cartCount();

    expect(await cubit.clearCart(), CartMutationResult.success);
    await waitForBackgroundSynchronization();
    expect(repository.clearCalls, 1);
    expect(cubit.state.status, CartStatus.empty);
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.badgeQuantity, 0);
  });

  test('older refresh cannot restore a cart after Clear', () async {
    final oldCart = Completer<Cart>();
    var cartReads = 0;
    repository
      ..currentCart = cart()
      ..currentCount = cartCount()
      ..onGetMyCart = () {
        cartReads++;
        return cartReads == 1
            ? oldCart.future
            : Future<Cart>.value(repository.currentCart);
      };

    final olderRefresh = cubit.refresh();
    expect(await cubit.clearCart(), CartMutationResult.success);
    oldCart.complete(cart(items: <CartLine>[cartLine(quantity: 2)]));
    await olderRefresh;
    await waitForBackgroundSynchronization();

    expect(cubit.state.status, CartStatus.empty);
    expect(cubit.state.badgeQuantity, 0);
  });

  test('simultaneous add operations are coalesced', () async {
    final gate = Completer<CartLine>();
    repository.currentLine = cartLine();
    repository.error = null;
    repository.onAdd = (_) => gate.future;
    final first = cubit.add(menuItemId: cartMenuItemId, quantity: 1);
    final second = cubit.add(menuItemId: cartMenuItemId, quantity: 1);
    expect(await second, CartMutationResult.busy);
    gate.complete(cartLine());
    expect(await first, CartMutationResult.success);
    await waitForBackgroundSynchronization();
  });

  test('background sync failure preserves successful mutation semantics',
      () async {
    repository.onGetMyCart = () async {
      throw const FailureException(Failure(FailureCode.network));
    };

    expect(
      await cubit.add(menuItemId: cartMenuItemId, quantity: 1),
      CartMutationResult.success,
    );
    await waitForBackgroundSynchronization();
    expect(cubit.state.hasError, isTrue);
    expect(cubit.state.isSynchronizing, isFalse);
    expect(cubit.state.isSynchronizationFailure, isTrue);
    expect(cubit.state.failure?.code, FailureCode.network);
  });

  test('older refresh cannot overwrite a newer add snapshot', () async {
    final oldCart = Completer<Cart>();
    var cartReads = 0;
    repository
      ..currentCart = cart(items: <CartLine>[cartLine(quantity: 4)])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 4)
      ..onGetMyCart = () {
        cartReads++;
        return cartReads == 1
            ? oldCart.future
            : Future<Cart>.value(repository.currentCart);
      };

    final olderRefresh = cubit.refresh();
    repository.currentCart = cart(items: <CartLine>[cartLine(quantity: 5)]);
    repository.currentCount = cartCount(linesCount: 1, totalQuantity: 5);
    expect(
      await cubit.add(menuItemId: cartMenuItemId, quantity: 5),
      CartMutationResult.success,
    );

    oldCart.complete(cart(items: <CartLine>[cartLine(quantity: 1)]));
    await olderRefresh;
    await waitForBackgroundSynchronization();

    expect(cubit.state.items.single.quantity, 5);
    expect(cubit.state.badgeQuantity, 5);
    expect(cubit.state.isMutating, isFalse);
  });

  test('pending refresh snapshot is replaced by post-add server snapshot',
      () async {
    final oldCart = Completer<Cart>();
    final pendingMutation = Completer<CartLine>();
    final emittedStates = <CartState>[];
    var cartReads = 0;
    repository.onAdd = (_) => pendingMutation.future;
    repository
      ..currentCart = cart(items: <CartLine>[cartLine(quantity: 1)])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 1)
      ..onGetMyCart = () {
        cartReads++;
        return cartReads == 1
            ? oldCart.future
            : Future<Cart>.value(repository.currentCart);
      };
    final subscription = cubit.stream.listen(emittedStates.add);

    final refresh = cubit.refresh();
    final mutation = cubit.add(menuItemId: cartMenuItemId, quantity: 8);
    oldCart.complete(cart(items: <CartLine>[cartLine(quantity: 1)]));
    await refresh;

    expect(cubit.state.isLoading, isTrue);
    expect(cubit.state.items, isEmpty);
    expect(
      emittedStates.any((state) => state.status == CartStatus.populated),
      isFalse,
    );

    repository
      ..currentCart = cart(items: <CartLine>[cartLine(quantity: 8)])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 8);
    pendingMutation.complete(cartLine(quantity: 8));
    expect(await mutation, CartMutationResult.success);
    await waitForBackgroundSynchronization();

    expect(cubit.state.items.single.quantity, 8);
    expect(cubit.state.badgeQuantity, 8);
    expect(cubit.state.isMutating, isFalse);
    await subscription.cancel();
  });

  test('older refresh cannot overwrite a newer line update', () async {
    final oldCart = Completer<Cart>();
    var cartReads = 0;
    repository
      ..currentCart = cart(items: <CartLine>[cartLine(quantity: 6)])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 6)
      ..onGetMyCart = () {
        cartReads++;
        return cartReads == 1
            ? oldCart.future
            : Future<Cart>.value(repository.currentCart);
      };

    final olderRefresh = cubit.refresh();
    repository.currentCart = cart(items: <CartLine>[cartLine(quantity: 7)]);
    repository.currentCount = cartCount(linesCount: 1, totalQuantity: 7);
    expect(
      await cubit.updateLineQuantity(cartLine(quantity: 7), 7),
      CartMutationResult.success,
    );

    oldCart.complete(cart(items: <CartLine>[cartLine(quantity: 2)]));
    await olderRefresh;
    await waitForBackgroundSynchronization();

    expect(cubit.state.items.single.quantity, 7);
    expect(cubit.state.badgeQuantity, 7);
    expect(cubit.state.isMutating, isFalse);
  });

  test('failed mutation restores an in-flight refresh and clears busy states',
      () async {
    final pendingCart = Completer<Cart>();
    final pendingMutation = Completer<CartLine>();
    repository.onGetMyCart = () => pendingCart.future;
    repository.onAdd = (_) => pendingMutation.future;

    final refresh = cubit.refresh();
    final mutation = cubit.add(menuItemId: cartMenuItemId, quantity: 1);
    pendingCart.complete(cart(items: <CartLine>[cartLine(quantity: 3)]));
    await refresh;
    expect(cubit.state.isMutating, isTrue);

    pendingMutation.completeError(
      const FailureException(Failure(FailureCode.network)),
    );
    expect(await mutation, CartMutationResult.failed);

    expect(cubit.state.status, CartStatus.populated);
    expect(cubit.state.items.single.quantity, 3);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.isMutating, isFalse);
    expect(cubit.state.failure?.code, FailureCode.network);
  });

  test('failed refresh and add preserve the last loaded cart', () async {
    repository
      ..currentCart = cart(items: <CartLine>[cartLine(quantity: 2)])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
    await cubit.load();
    expect(cubit.state.status, CartStatus.populated);

    final refreshFailure = Completer<Cart>();
    final mutationResult = Completer<CartLine>();
    repository.onGetMyCart = () => refreshFailure.future;
    repository.onAdd = (_) => mutationResult.future;

    final refresh = cubit.refresh();
    final mutation = cubit.add(menuItemId: cartMenuItemId, quantity: 3);
    refreshFailure.completeError(
      const FailureException(Failure(FailureCode.network)),
    );
    await refresh;

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.items.single.quantity, 2);
    expect(cubit.state.isMutating, isTrue);

    mutationResult.completeError(
      const FailureException(Failure(FailureCode.validation)),
    );
    expect(await mutation, CartMutationResult.failed);

    expect(cubit.state.status, CartStatus.populated);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.items.single.quantity, 2);
    expect(cubit.state.badgeQuantity, 2);
    expect(cubit.state.isMutating, isFalse);
    expect(cubit.state.failure?.code, FailureCode.validation);
  });

  test('closing during pending refresh and mutation emits no late states',
      () async {
    final pendingCart = Completer<Cart>();
    final pendingMutation = Completer<CartLine>();
    repository.onGetMyCart = () => pendingCart.future;
    repository.onAdd = (_) => pendingMutation.future;
    final states = <CartState>[];
    final subscription = cubit.stream.listen(states.add);

    final refresh = cubit.refresh();
    final mutation = cubit.add(menuItemId: cartMenuItemId, quantity: 1);
    await cubit.close();
    final stateCountAtClose = states.length;
    pendingCart.complete(cart(items: <CartLine>[cartLine(quantity: 2)]));
    pendingMutation.complete(cartLine());

    await refresh;
    expect(await mutation, CartMutationResult.busy);
    expect(states.length, stateCountAtClose);
    await subscription.cancel();
  });

  test('visible line quantity updates immediately while a mutation is pending',
      () async {
    final line = cartLine(quantity: 2);
    final pendingUpdate = Completer<CartUpdateResult>();
    final updateStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2)
      ..onUpdate = (_) {
        updateStarted.complete();
        return pendingUpdate.future;
      };
    await cubit.load();

    final mutation = cubit.updateLineQuantity(line, 3);
    await updateStarted.future;
    // The server has not confirmed anything yet, but the UI must already
    // reflect the requested quantity and project the badge.
    expect(cubit.state.items.single.quantity, 3);
    expect(cubit.state.badgeQuantity, 3);
    expect(cubit.state.isLineMutating(line), isTrue);

    repository.currentCart = cart(items: <CartLine>[cartLine(quantity: 3)]);
    repository.currentCount = cartCount(linesCount: 1, totalQuantity: 3);
    pendingUpdate.complete(const CartUpdateResult(isRemoved: false));
    expect(await mutation, CartMutationResult.success);
    await waitForBackgroundSynchronization();
    expect(cubit.state.items.single.quantity, 3);
    expect(cubit.state.badgeQuantity, 3);
    expect(cubit.state.isLineMutating(line), isFalse);
  });

  test('removal hides the exact line immediately and badges reflect it',
      () async {
    final line = cartLine(quantity: 2);
    final pendingUpdate = Completer<CartUpdateResult>();
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2)
      ..onUpdate = (_) => pendingUpdate.future;
    await cubit.load();

    final mutation = cubit.updateLineQuantity(line, 0);
    // Optimistic removal: the confirmed removal is still pending, but the
    // line is already hidden and the badge projects zero.
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.badgeQuantity, 0);

    repository.currentCart = cart();
    repository.currentCount = cartCount();
    pendingUpdate.complete(const CartUpdateResult(isRemoved: true));
    expect(await mutation, CartMutationResult.success);
    await waitForBackgroundSynchronization();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.badgeQuantity, 0);
  });

  test('a failed mutation rolls the optimistic quantity and badge back',
      () async {
    final line = cartLine(quantity: 2);
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2)
      ..onUpdate = (_) async => throw const FailureException(
            Failure(FailureCode.network),
          );
    await cubit.load();

    expect(
      await cubit.updateLineQuantity(line, 3),
      CartMutationResult.failed,
    );
    expect(cubit.state.items.single.quantity, 2);
    expect(cubit.state.badgeQuantity, 2);
    expect(cubit.state.isMutating, isFalse);
    expect(cubit.state.failure?.code, FailureCode.network);
  });

  test('unavailable lines cannot be increased but can be decreased and removed',
      () async {
    final line = cartLine(quantity: 2, available: false);
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
    await cubit.load();

    // Increase is rejected before any request is sent.
    expect(await cubit.updateLineQuantity(line, 3), CartMutationResult.failed);
    expect(repository.lastUpdate, isNull);

    // Decrease is allowed.
    repository.currentCart = cart(items: <CartLine>[
      cartLine(quantity: 1, available: false),
    ]);
    repository.currentCount = cartCount(linesCount: 1, totalQuantity: 1);
    expect(await cubit.updateLineQuantity(line, 1), CartMutationResult.success);
    expect(repository.lastUpdate?.quantity, 1);
    await waitForBackgroundSynchronization();

    // Removal is allowed.
    repository.currentCart = cart();
    repository.currentCount = cartCount();
    repository.currentUpdateResult = const CartUpdateResult(isRemoved: true);
    expect(await cubit.updateLineQuantity(line, 0), CartMutationResult.success);
    expect(repository.lastUpdate?.quantity, 0);
  });

  test('a removed line rejects every quantity change', () async {
    final line = cartLine(quantity: 1, removed: true);
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 1);
    await cubit.load();

    expect(await cubit.updateLineQuantity(line, 0), CartMutationResult.failed);
    expect(await cubit.updateLineQuantity(line, 1), CartMutationResult.failed);
    expect(repository.lastUpdate, isNull);
  });

  test('coalesced rapid taps never exceed the documented 99 maximum',
      () async {
    final line = cartLine(quantity: 98);
    final gate = Completer<CartUpdateResult>();
    final sentQuantities = <int>[];
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 98)
      ..onUpdate = (mutation) {
        sentQuantities.add(mutation.quantity);
        return gate.future;
      };
    await cubit.load();

    final first = cubit.changeLineQuantityBy(line, 1);
    final second = cubit.changeLineQuantityBy(line, 1);
    expect(sentQuantities, <int>[99]);
    expect(cubit.state.items.single.quantity, 99);
    repository.currentCart = cart(items: <CartLine>[cartLine(quantity: 99)]);
    repository.currentCount = cartCount(linesCount: 1, totalQuantity: 99);
    gate.complete(const CartUpdateResult(isRemoved: false));
    expect(await first, CartMutationResult.success);
    expect(await second, CartMutationResult.success);
    await waitForBackgroundSynchronization();

    // Out-of-range absolute targets are rejected before a request.
    expect(
      await cubit.updateLineQuantity(line, 100),
      CartMutationResult.failed,
    );
    expect(sentQuantities, <int>[99]);

    // Setting the already-displayed quantity is a no-op, not a request.
    final display = cubit.state.items.single;
    expect(
      await cubit.updateLineQuantity(display, display.quantity),
      CartMutationResult.success,
    );
    expect(sentQuantities, <int>[99]);
  });

  test('add and update reject quantities above 99 before a request',
      () async {
    repository.currentCart = cart();
    repository.currentCount = cartCount();

    expect(
      await cubit.add(menuItemId: cartMenuItemId, quantity: 100),
      CartMutationResult.failed,
    );
    expect(repository.lastAdd, isNull);
    expect(
      await cubit.updateLineQuantity(
        cartLine(quantity: 1),
        100,
      ),
      CartMutationResult.failed,
    );
    expect(repository.lastUpdate, isNull);
  });

  test('badge stays projected when the sync after a confirmed mutation fails',
      () async {
    final line = cartLine(quantity: 2);
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
    await cubit.load();
    repository.onGetMyCart = () async => throw const FailureException(
          Failure(FailureCode.network),
        );

    expect(
      await cubit.updateLineQuantity(line, 3),
      CartMutationResult.success,
    );
    await waitForBackgroundSynchronization();

    expect(cubit.state.isSynchronizationFailure, isTrue);
    expect(cubit.state.items.single.quantity, 3);
    // The last authoritative GetCount said 2; the confirmed +1 stays
    // projected instead of the badge presenting a stale 2 as current.
    expect(cubit.state.badgeQuantity, 3);
  });

  test('confirmed Clear shows an empty cart and zero badge immediately',
      () async {
    final pendingClear = Completer<void>();
    final clearStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[cartLine(quantity: 2)])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2)
      ..onClear = () {
        clearStarted.complete();
        return pendingClear.future;
      };
    await cubit.load();

    final clear = cubit.clearCart();
    await clearStarted.future;
    expect(cubit.state.isClearing, isTrue);

    repository.currentCart = cart();
    repository.currentCount = cartCount();
    pendingClear.complete();
    expect(await clear, CartMutationResult.success);
    // Before the background sync completes, content and badge are already
    // empty because the Clear was confirmed, not pending.
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.badgeQuantity, 0);
    await waitForBackgroundSynchronization();
    expect(cubit.state.badgeQuantity, 0);
  });

  test('older mutation response cannot overwrite a newer requested quantity',
      () async {
    final line = cartLine(quantity: 2);
    final firstUpdate = Completer<CartUpdateResult>();
    final secondUpdate = Completer<CartUpdateResult>();
    final firstStarted = Completer<void>();
    final secondStarted = Completer<void>();
    repository
      ..currentCart = cart(items: <CartLine>[line])
      ..currentCount = cartCount(linesCount: 1, totalQuantity: 2)
      ..onUpdate = (_) {
        if (!firstStarted.isCompleted) {
          firstStarted.complete();
          return firstUpdate.future;
        }
        secondStarted.complete();
        return secondUpdate.future;
      };
    await cubit.load();

    final first = cubit.changeLineQuantityBy(line, 1);
    await firstStarted.future;
    final second = cubit.changeLineQuantityBy(line, 1);
    await Future<void>.value();
    firstUpdate.complete(const CartUpdateResult(isRemoved: false));
    await secondStarted.future;

    // The first (older) confirmation must not drag the visible quantity back.
    expect(cubit.state.items.single.quantity, 4);

    repository.currentCart = cart(items: <CartLine>[cartLine(quantity: 4)]);
    repository.currentCount = cartCount(linesCount: 1, totalQuantity: 4);
    secondUpdate.complete(const CartUpdateResult(isRemoved: false));
    expect(await first, CartMutationResult.success);
    expect(await second, CartMutationResult.success);
    expect(cubit.state.items.single.quantity, 4);
  });

  test('add-on order does not change exact configuration identity', () {
    expect(
      cartMutationKey(cartMenuItemId, cartOptionId, <String>['a', 'b']),
      cartMutationKey(cartMenuItemId, cartOptionId, <String>['b', 'a']),
    );
    expect(
      cartMutationKey(cartMenuItemId, cartOptionId, <String>['a', 'b']),
      isNot(cartMutationKey(cartMenuItemId, otherCartOptionId, <String>['a', 'b'])),
    );
    expect(
      cartMutationKey(cartMenuItemId, null, const <String>[]),
      isNot(cartMutationKey(cartMenuItemId, cartOptionId, const <String>[])),
    );
    // Case-insensitive identity: the same server-edited IDs dedupe reliably.
    expect(
      cartMutationKey('MENU', 'OPTION', <String>['ADDON']),
      cartMutationKey('menu', 'option', <String>['addon']),
    );
  });

  test(
    'remote failures surface as a failed mutation without stale optimism',
    () async {
      repository.error = const FailureException(Failure(FailureCode.network));
      expect(
        await cubit.add(menuItemId: cartMenuItemId, quantity: 1),
        CartMutationResult.failed,
      );
      expect(cubit.state.isMutating, isFalse);
      expect(cubit.state.failure?.code, FailureCode.network);
    },
  );
}
