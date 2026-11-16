import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_mutation.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
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
        repository.currentLine,
      );
      expect(repository.lastUpdate, mutation);
      expect(await GetMyCartUseCase(repository)(), repository.currentCart);
      expect(await GetCartCountUseCase(repository)(), repository.currentCount);
    },
  );

  test(
    'positive documented quantities are enforced before a request',
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
}
