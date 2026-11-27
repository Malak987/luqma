import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';

import '../../cart/support/cart_fixtures.dart';

/// Models the shell's cart dependency without calling the network or loading it.
Widget withTestCart(Widget child) => BlocProvider<CartCubit>(
      create: (_) {
        final repository = FakeCartRepository();
        return CartCubit(
          addToCartUseCase: AddToCartUseCase(repository),
          updateToCartUseCase: UpdateToCartUseCase(repository),
          clearCartUseCase: ClearCartUseCase(repository),
          getMyCartUseCase: GetMyCartUseCase(repository),
        );
      },
      child: child,
    );
