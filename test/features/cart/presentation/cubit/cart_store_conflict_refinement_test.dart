import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import '../../support/cart_fixtures.dart';

void main() {
  test('coded store conflict preserves the current cart and never clears it',
      () async {
    final existing = cartLine();
    final repo = FakeCartRepository()
      ..currentCart = cart(items: [existing])
      ..onAdd = (_) async => throw const FailureException(
          Failure(FailureCode.validation, backendCode: 'CART_STORE_CONFLICT'));
    final cubit = CartCubit(
        addToCartUseCase: AddToCartUseCase(repo),
        updateToCartUseCase: UpdateToCartUseCase(repo),
        clearCartUseCase: ClearCartUseCase(repo),
        getMyCartUseCase: GetMyCartUseCase(repo));
    addTearDown(cubit.close);
    await cubit.load();
    final result =
        await cubit.add(menuItemId: '00000000-0000-4000-8000-000000000999', quantity: 1);
    expect(result, CartMutationResult.storeConflict);
    expect(cubit.state.items, [existing]);
    expect(repo.clearCalls, 0);
  });
}
