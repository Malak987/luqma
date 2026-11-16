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
