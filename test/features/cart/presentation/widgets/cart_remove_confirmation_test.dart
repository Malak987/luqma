import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/get_my_cart_use_case.dart';
import 'package:luqma_app/features/cart/domain/usecases/update_to_cart_use_case.dart';
import 'package:luqma_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:luqma_app/features/cart/presentation/pages/cart_page.dart';
import '../../support/cart_fixtures.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets('cancel removal keeps line $locale dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final line = cartLine(quantity: 2);
        final repo = FakeCartRepository()..currentCart = cart(items: [line]);
        final cubit = CartCubit(
            addToCartUseCase: AddToCartUseCase(repo),
            updateToCartUseCase: UpdateToCartUseCase(repo),
            clearCartUseCase: ClearCartUseCase(repo),
            getMyCartUseCase: GetMyCartUseCase(repo));
        addTearDown(cubit.close);
        await cubit.load();
        await tester.pumpWidget(BlocProvider.value(
            value: cubit,
            child: MaterialApp(
              locale: locale,
              theme: dark ? AppTheme.dark : AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.5),
                      disableAnimations: true),
                  child: child!),
              home: const CartPage(),
            )));
        final remove = find.byKey(Key('cart_remove_${line.id}'));
        await tester.ensureVisible(remove);
        await tester.tap(remove);
        await tester.pumpAndSettle();
        expect(find.text(AppLocalizations(locale).cart.removeConfirmTitle),
            findsOneWidget);
        await tester.tap(find.byKey(const Key('cart_remove_cancel')));
        await tester.pumpAndSettle();
        expect(repo.lastUpdate, isNull);
        expect(cubit.state.items, [line]);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('confirmation rejects a replaced cart line', (tester) async {
    final line = cartLine(quantity: 2);
    final repo = FakeCartRepository()..currentCart = cart(items: [line]);
    final cubit = CartCubit(
        addToCartUseCase: AddToCartUseCase(repo),
        updateToCartUseCase: UpdateToCartUseCase(repo),
        clearCartUseCase: ClearCartUseCase(repo),
        getMyCartUseCase: GetMyCartUseCase(repo));
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CartPage(),
        )));
    await tester.tap(find.byKey(Key('cart_remove_${line.id}')));
    await tester.pumpAndSettle();
    repo.currentCart =
        cart(items: [cartLine(id: otherCartLineId, quantity: 2)]);
    await cubit.refresh(force: true);
    await tester.pump();
    await tester.tap(find.byKey(const Key('cart_remove_confirm')));
    await tester.pumpAndSettle();
    expect(repo.lastUpdate, isNull);
    expect(cubit.state.items.single.id, otherCartLineId);
    expect(find.text(AppLocalizations(const Locale('en')).cart.lineChanged),
        findsOneWidget);
  });
}
