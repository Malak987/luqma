import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/cart/domain/entities/cart.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_line.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
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
      getMyCartUseCase: GetMyCartUseCase(repository),
      getCartCountUseCase: GetCartCountUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

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
      expect(result, CartMutationResult.success);
      expect(repository.lastAdd?.menuItemId, cartMenuItemId);
      expect(cubit.state.items.single.quantity, 3);
      expect(cubit.state.badgeQuantity, 3);
    },
  );

  test(
    'quantity one cannot be transformed into an undocumented remove call',
    () async {
      final result = await cubit.updateLineQuantity(cartLine(quantity: 1), 0);
      expect(result, CartMutationResult.failed);
      expect(repository.lastUpdate, isNull);
    },
  );

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
  });

  test('authoritative sync failure keeps synchronizationFailed semantics',
      () async {
    repository.onGetMyCart = () async {
      throw const FailureException(Failure(FailureCode.network));
    };

    expect(
      await cubit.add(menuItemId: cartMenuItemId, quantity: 1),
      CartMutationResult.synchronizationFailed,
    );
    expect(cubit.state.hasError, isTrue);
    expect(cubit.state.isMutating, isFalse);
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

    expect(cubit.state.isLoading, isTrue);
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
