import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:luqma_app/features/favorites/presentation/pages/favorites_page.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:luqma_app/features/favorites/domain/queries/favorite_paging.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorite_menu_item.dart';
import 'package:luqma_app/features/favorites/domain/usecases/add_to_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/get_my_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/remove_from_favorites_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../support/favorite_fixtures.dart';

void main() {
  Widget host(Widget child, {required Locale locale, required bool dark}) {
    return MaterialApp(
      locale: locale,
      theme: dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders Favorites loading, error and empty states',
      (tester) async {
    Future<void> noop() async {}
    await tester.pumpWidget(
      host(
        FavoritesPageContent(
          state: FavoritesState(status: FavoritesStatus.loading),
          onRetry: noop,
          onLoadMore: noop,
          onRetryMore: noop,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    expect(find.byKey(const Key('favorites_loading_state')), findsOneWidget);

    await tester.pumpWidget(
      host(
        FavoritesPageContent(
          state: FavoritesState(status: FavoritesStatus.error),
          onRetry: noop,
          onLoadMore: noop,
          onRetryMore: noop,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    expect(find.byKey(const Key('favorites_error_state')), findsOneWidget);

    await tester.pumpWidget(
      host(
        FavoritesPageContent(
          state: FavoritesState(status: FavoritesStatus.empty),
          onRetry: noop,
          onLoadMore: noop,
          onRetryMore: noop,
        ),
        locale: const Locale('en'),
        dark: false,
      ),
    );
    expect(find.byKey(const Key('favorites_empty_state')), findsOneWidget);
  });

  testWidgets('building a favorite heart makes no membership API request',
      (tester) async {
    final repository = FakeFavoritesRepository();
    final cubit = FavoritesCubit(
      addToFavoritesUseCase: AddToFavoritesUseCase(repository),
      removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repository),
      getMyFavoritesUseCase: GetMyFavoritesUseCase(repository),
      paging: const FavoritePaging(),
      repository: repository,
      getAuthenticatedUserId: () async => 'widget-test-user',
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<FavoritesCubit>.value(
        value: cubit,
        child: host(
          FavoritesPageContent(
            state: FavoritesState(
              status: FavoritesStatus.populated,
              items: <FavoriteMenuItem>[favoriteItem()],
              totalCount: 1,
            ),
            onRetry: () async {},
            onLoadMore: () async {},
            onRetryMore: () async {},
          ),
          locale: const Locale('en'),
          dark: false,
        ),
      ),
    );

    expect(repository.lastIsFavorite, isNull);
    expect(repository.pageReads, 0);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  for (final locale in <Locale>[const Locale('ar'), const Locale('en')]) {
    for (final dark in <bool>[false, true]) {
      testWidgets(
        'refresh failure keeps Favorites visible in ${locale.languageCode} ${dark ? 'dark' : 'light'}',
        (tester) async {
          var retries = 0;
          Future<void> retry() async {
            retries++;
          }
          Future<void> noop() async {}
          final copy = AppLocalizations(locale).favorites;

          await tester.pumpWidget(
            host(
              FavoritesPageContent(
                state: FavoritesState(
                  status: FavoritesStatus.error,
                  items: [favoriteItem()],
                  totalCount: 1,
                ),
                onRetry: retry,
                onLoadMore: noop,
                onRetryMore: noop,
              ),
              locale: locale,
              dark: dark,
            ),
          );

          expect(find.byKey(const Key('favorites_error_state')), findsNothing);
          expect(find.byKey(const Key('favorites_refresh_error')), findsOneWidget);
          expect(
            find.byKey(Key('favorite_item_$favoriteMenuItemId')),
            findsOneWidget,
          );
          expect(find.text(copy.actionFailed), findsOneWidget);
          expect(find.text(copy.retry), findsOneWidget);

          await tester.tap(find.byKey(const Key('favorites_refresh_retry')));
          await tester.pump();
          expect(retries, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final locale in <Locale>[const Locale('ar'), const Locale('en')]) {
    for (final dark in <bool>[false, true]) {
      testWidgets(
        'Favorite item is responsive in ${locale.languageCode} ${dark ? 'dark' : 'light'}',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 568));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          Future<void> noop() async {}
          await tester.pumpWidget(
            host(
              MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: FavoritesPageContent(
                  state: FavoritesState(
                    status: FavoritesStatus.populated,
                    items: [favoriteItem()],
                    totalCount: 1,
                  ),
                  onRetry: noop,
                  onLoadMore: noop,
                  onRetryMore: noop,
                ),
              ),
              locale: locale,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(Key('favorite_item_$favoriteMenuItemId')),
            findsOneWidget,
          );
          expect(
            find.text(locale.languageCode == 'ar' ? 'طبق النيل' : 'Nile dish'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
