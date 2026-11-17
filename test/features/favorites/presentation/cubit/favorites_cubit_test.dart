import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorite_menu_item.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorites_page.dart';
import 'package:luqma_app/features/favorites/domain/queries/favorite_paging.dart';
import 'package:luqma_app/features/favorites/domain/usecases/add_to_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/get_favorites_count_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/get_my_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/is_favorite_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/remove_from_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_state.dart';

import '../../support/favorite_fixtures.dart';

void main() {
  late FakeFavoritesRepository repository;
  late FavoritesCubit cubit;

  setUp(() {
    repository = FakeFavoritesRepository();
    cubit = FavoritesCubit(
      addToFavoritesUseCase: AddToFavoritesUseCase(repository),
      removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repository),
      getMyFavoritesUseCase: GetMyFavoritesUseCase(repository),
      isFavoriteUseCase: IsFavoriteUseCase(repository),
      getFavoritesCountUseCase: GetFavoritesCountUseCase(repository),
      paging: const FavoritePaging(),
    );
  });

  tearDown(() => cubit.close());

  test('load uses authoritative page and count for content and badge', () async {
    repository
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalCount: 1,
      )
      ..currentCount = 1;

    await cubit.load();

    expect(cubit.state.status, FavoritesStatus.populated);
    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(cubit.state.badgeCount, 1);
    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
  });

  test('add first resolves IsFavorite then synchronizes list and count',
      () async {
    repository
      ..statuses[favoriteMenuItemId] = false
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalCount: 1,
      )
      ..currentCount = 1;

    expect(await cubit.toggle(favoriteMenuItemId), FavoriteMutationResult.success);
    expect(repository.lastIsFavorite, favoriteMenuItemId);
    expect(repository.lastAdded, favoriteMenuItemId);
    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(cubit.state.badgeCount, 1);
  });

  test('remove has no optimistic list deletion and refreshes count', () async {
    repository
      ..statuses[favoriteMenuItemId] = true
      ..currentPage = favoritesPage()
      ..currentCount = 0;

    expect(await cubit.toggle(favoriteMenuItemId), FavoriteMutationResult.success);
    expect(repository.lastRemoved, favoriteMenuItemId);
    expect(cubit.state.status, FavoritesStatus.empty);
    expect(cubit.state.badgeCount, 0);
    expect(cubit.state.isFavorite(favoriteMenuItemId), isFalse);
  });

  test('duplicate concurrent toggles share one mutation', () async {
    final gate = Completer<FavoriteMenuItem>();
    repository
      ..statuses[favoriteMenuItemId] = false
      ..onAdd = (_) => gate.future
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalCount: 1,
      )
      ..currentCount = 1;

    final first = cubit.toggle(favoriteMenuItemId);
    final second = cubit.toggle(favoriteMenuItemId);
    await Future<void>.delayed(Duration.zero);
    gate.complete(favoriteItem());

    expect(await first, FavoriteMutationResult.success);
    expect(await second, FavoriteMutationResult.success);
    expect(repository.lastAdded, favoriteMenuItemId);
  });

  test('older page refresh cannot overwrite a completed favorite mutation',
      () async {
    final oldPage = Completer<FavoritesPage>();
    var reads = 0;
    repository
      ..statuses[favoriteMenuItemId] = false
      ..onGetPage = (page, _) {
        reads++;
        return reads == 1 ? oldPage.future : Future<FavoritesPage>.value(
          favoritesPage(
            items: <FavoriteMenuItem>[favoriteItem()],
            totalCount: 1,
          ),
        );
      }
      ..currentCount = 1;

    final olderRefresh = cubit.refresh();
    expect(await cubit.toggle(favoriteMenuItemId), FavoriteMutationResult.success);
    oldPage.complete(favoritesPage());
    await olderRefresh;

    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(cubit.state.badgeCount, 1);
  });

  test('pagination retains items, deduplicates and exposes next-page failure',
      () async {
    var fail = false;
    repository
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalCount: 2,
        totalPages: 2,
        hasNextPage: true,
      )
      ..currentCount = 2
      ..onGetPage = (page, _) async {
        if (page == 1) return repository.currentPage;
        if (fail) {
          throw const FailureException(Failure(FailureCode.network));
        }
        return favoritesPage(
          pageNumber: 2,
          totalPages: 2,
          totalCount: 2,
          hasPreviousPage: true,
          items: <FavoriteMenuItem>[
            favoriteItem(),
            favoriteItem(
              id: '40000000-dddd-4000-8000-000000000004',
              menuItemId: otherFavoriteMenuItemId,
            ),
          ],
        );
      };

    await cubit.load();
    await cubit.loadNextPage();
    expect(cubit.state.items.length, 2);
    expect(cubit.state.pageNumber, 2);

    fail = true;
    // A fresh first-page load restores hasNextPage; then its continuation fails.
    await cubit.refresh();
    await cubit.loadNextPage();
    expect(cubit.state.nextPageFailure?.code, FailureCode.network);
  });

  test('close during an in-flight request emits no late state', () async {
    final page = Completer<FavoritesPage>();
    repository.onGetPage = (_, __) => page.future;
    final states = <FavoritesState>[];
    final subscription = cubit.stream.listen(states.add);

    final load = cubit.load();
    await cubit.close();
    final countAtClose = states.length;
    page.complete(favoritesPage());
    await load;

    expect(states.length, countAtClose);
    await subscription.cancel();
  });
}
