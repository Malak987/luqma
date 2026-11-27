import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorite_menu_item.dart';
import 'package:luqma_app/features/favorites/domain/queries/favorite_paging.dart';
import 'package:luqma_app/features/favorites/domain/usecases/add_to_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/get_my_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/remove_from_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:luqma_app/features/favorites/presentation/pages/favorites_page.dart';
import 'package:luqma_app/features/favorites/presentation/widgets/favorite_toggle_button.dart';
import '../../support/favorite_fixtures.dart';

void main() {
  testWidgets(
      'heart reflects pending optimistic favorite and rolls back on failure',
      (tester) async {
    final response = Completer<FavoriteMenuItem>();
    final repository = FakeFavoritesRepository()
      ..onAdd = (_) => response.future;
    final cubit = FavoritesCubit(
      addToFavoritesUseCase: AddToFavoritesUseCase(repository),
      removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repository),
      getMyFavoritesUseCase: GetMyFavoritesUseCase(repository),
      paging: const FavoritePaging(),
      repository: repository,
      getAuthenticatedUserId: () async => 'test-user',
    );
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<FavoritesCubit>.value(
      value: cubit,
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: const Scaffold(
            body: FavoriteToggleButton(menuItemId: favoriteMenuItemId)),
      ),
    ));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('favorite_toggle_$favoriteMenuItemId')));
    await tester.pump();
    expect(cubit.state.isPending(favoriteMenuItemId), isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    response.completeError(Exception('test failure'));
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(
        find.text(AppLocalizations(const Locale('en')).favorites.actionFailed),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'remove from favorites updates menu heart and failed remove rolls back',
      (tester) async {
    final pending = Completer<void>();
    final repo = FakeFavoritesRepository()
      ..currentPage = favoritesPage(items: [favoriteItem()], totalCount: 1)
      ..onRemove = (_) => pending.future;
    final cubit = FavoritesCubit(
        addToFavoritesUseCase: AddToFavoritesUseCase(repo),
        removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repo),
        getMyFavoritesUseCase: GetMyFavoritesUseCase(repo),
        paging: const FavoritePaging(),
        repository: repo,
        getAuthenticatedUserId: () async => 'test-user');
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<FavoritesCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!),
          home: const Scaffold(
              body: Column(children: [
            FavoriteToggleButton(menuItemId: favoriteMenuItemId),
            Expanded(child: FavoritesPage()),
          ])),
        )));
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
    final page = find.byType(FavoritesPage);
    final pageHeart = find.descendant(
        of: page,
        matching: find.byKey(const Key('favorite_toggle_$favoriteMenuItemId')));
    await tester.tap(pageHeart);
    await tester.pump();
    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
    expect(find.byKey(const Key('favorites_empty_state')), findsOneWidget);
    expect(cubit.state.isPending(favoriteMenuItemId), isTrue);
    expect(repo.removeCalls, 1);
    pending.completeError(Exception('test error'));
    await tester.pump();
    await tester.pump();
    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(
        find.text(AppLocalizations(const Locale('en')).favorites.actionFailed),
        findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'rapid opposite taps are coalesced without duplicate add requests',
      (tester) async {
    final pending = Completer<FavoriteMenuItem>();
    final repo = FakeFavoritesRepository()..onAdd = (_) => pending.future;
    final cubit = FavoritesCubit(
        addToFavoritesUseCase: AddToFavoritesUseCase(repo),
        removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repo),
        getMyFavoritesUseCase: GetMyFavoritesUseCase(repo),
        paging: const FavoritePaging(),
        repository: repo,
        getAuthenticatedUserId: () async => 'test-user');
    await cubit.load();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<FavoritesCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!),
          home: const Scaffold(
              body: FavoriteToggleButton(menuItemId: favoriteMenuItemId)),
        )));
    final heart = find.byKey(const Key('favorite_toggle_$favoriteMenuItemId'));
    await tester.tap(heart);
    await tester.pump();
    expect(cubit.state.isPending(favoriteMenuItemId), isTrue);
    await tester.tap(heart);
    await tester.pump();
    expect(repo.addCalls, 1);
    pending.complete(favoriteItem());
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(repo.removeCalls, 1);
    expect(cubit.state.isFavorite(favoriteMenuItemId), isFalse);
    expect(cubit.state.isPending(favoriteMenuItemId), isFalse);
    expect(tester.takeException(), isNull);
  });
}
