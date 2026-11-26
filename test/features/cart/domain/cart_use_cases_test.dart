import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_mutation.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_cart_count_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';

import '../support/cart_fixtures.dart';

void main() {
  test(
    'cart use cases forward documented inputs and authoritative snapshots',
    () async {
      final repository = FakeCartRepository()
        ..currentCart = cart(items: [cartLine()])
        ..currentCount = cartCount(linesCount: 1, totalQuantity: 2);
      final mutation = CartMutation(
        menuItemId: cartMenuItemId,
        quantity: 2,
        menuItemOptionId: cartOptionId,
        addonIds: const <String>[cartAddonId],
      );

      expect(
        await AddToCartUseCase(repository)(mutation),
        repository.currentLine,
      );
      expect(repository.lastAdd, mutation);
      expect(
        await UpdateToCartUseCase(repository)(mutation),
        repository.currentUpdateResult,
      );
      expect(repository.lastUpdate, mutation);
      await ClearCartUseCase(repository)();
      expect(repository.clearCalls, 1);
      expect(await GetMyCartUseCase(repository)(), repository.currentCart);
      expect(await GetCartCountUseCase(repository)(), repository.currentCount);
    },
  );

  test('UpdateToCart permits confirmed quantity-zero removal', () async {
    final repository = FakeCartRepository();
    final removal = CartMutation(
      menuItemId: cartMenuItemId,
      quantity: 0,
      menuItemOptionId: cartOptionId,
      addonIds: const <String>[cartAddonId],
    );

    await UpdateToCartUseCase(repository)(removal);

    expect(repository.lastUpdate, removal);
  });

  test('UpdateToCart rejects a negative quantity before a request', () async {
    final repository = FakeCartRepository();

    expect(
      () => UpdateToCartUseCase(repository)(
        CartMutation(menuItemId: cartMenuItemId, quantity: -1),
      ),
      throwsA(
        isA<FailureException>().having(
          (error) => error.failure.code,
          'code',
          FailureCode.validation,
        ),
      ),
    );
    expect(repository.lastUpdate, isNull);
  });

  test(
    'positive documented AddToCart quantities are enforced before a request',
    () async {
      final repository = FakeCartRepository();
      final invalid = CartMutation(menuItemId: cartMenuItemId, quantity: 0);
      expect(
        () => AddToCartUseCase(repository)(invalid),
        throwsA(
          isA<FailureException>().having(
            (error) => error.failure.code,
            'code',
            FailureCode.validation,
          ),
        ),
      );
      expect(repository.lastAdd, isNull);
    },
  );

  test('AddToCart enforces the documented 1-99 quantity bound', () async {
    final repository = FakeCartRepository();

    for (final quantity in <int>[1, 99]) {
      await AddToCartUseCase(repository)(
        CartMutation(menuItemId: cartMenuItemId, quantity: quantity),
      );
      expect(repository.lastAdd?.quantity, quantity);
      repository.lastAdd = null;
    }

    for (final quantity in <int>[0, -1, 100]) {
      expect(
        () => AddToCartUseCase(repository)(
          CartMutation(menuItemId: cartMenuItemId, quantity: quantity),
        ),
        throwsA(
          isA<FailureException>().having(
            (error) => error.failure.code,
            'code',
            FailureCode.validation,
          ),
        ),
      );
      expect(repository.lastAdd, isNull);
    }
  });

  test('UpdateToCart enforces the documented 0-99 quantity bound', () async {
    final repository = FakeCartRepository();

    for (final quantity in <int>[0, 1, 99]) {
      await UpdateToCartUseCase(repository)(
        CartMutation(menuItemId: cartMenuItemId, quantity: quantity),
      );
      expect(repository.lastUpdate?.quantity, quantity);
      repository.lastUpdate = null;
    }

    for (final quantity in <int>[-1, 100]) {
      expect(
        () => UpdateToCartUseCase(repository)(
          CartMutation(menuItemId: cartMenuItemId, quantity: quantity),
        ),
        throwsA(
          isA<FailureException>().having(
            (error) => error.failure.code,
            'code',
            FailureCode.validation,
          ),
        ),
      );
      expect(repository.lastUpdate, isNull);
    }
  });
}
