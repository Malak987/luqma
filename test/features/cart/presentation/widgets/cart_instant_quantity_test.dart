import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/features/cart/domain/entities/cart_update_result.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/cart/presentation/pages/cart_page.dart';
import '../../support/cart_fixtures.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets(
        'quantity updates before server response and rolls back on failure $locale',
        (tester) async {
      final pending = Completer<CartUpdateResult>();
      final line = cartLine(quantity: 2);
      final repo = FakeCartRepository()
        ..currentCart = cart(items: [line])
        ..onUpdate = (_) => pending.future;
      final cubit = CartCubit(
          addToCartUseCase: AddToCartUseCase(repo),
          updateToCartUseCase: UpdateToCartUseCase(repo),
          clearCartUseCase: ClearCartUseCase(repo),
          getMyCartUseCase: GetMyCartUseCase(repo));
      await cubit.load();
      addTearDown(cubit.close);
      final copy = AppLocalizations(locale);
      await tester.pumpWidget(BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CartPage(),
          )));
      final increase = find.byTooltip(copy.cart.increase);
      await tester.ensureVisible(increase);
      await tester.tap(increase);
      await tester.pump();
      expect(cubit.state.items.single.quantity, 3);
      expect(cubit.state.isLineMutating(line), isTrue);
      expect(find.text(copy.catalog.number(3)), findsWidgets);
      pending.completeError(Exception('test failure'));
      await tester.pump();
      await tester.pump();
      expect(cubit.state.items.single.quantity, 2);
      expect(find.text(copy.cart.actionFailed), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
