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

  Future<List<Future<void>>> startConcurrentStatusLookups({
    required Completer<bool> firstResult,
    required Completer<bool> secondResult,
    String firstMenuItemId = favoriteMenuItemId,
    String secondMenuItemId = otherFavoriteMenuItemId,
  }) async {
    final firstStarted = Completer<void>();
    final secondStarted = Completer<void>();
    repository.onIsFavorite = (menuItemId) {
      if (menuItemId == firstMenuItemId) {
        firstStarted.complete();
        return firstResult.future;
      }
      secondStarted.complete();
      return secondResult.future;
    };
    final requests = <Future<void>>[
      cubit.ensureFavoriteStatus(firstMenuItemId),
      cubit.ensureFavoriteStatus(secondMenuItemId),
    ];
    await Future.wait<void>(<Future<void>>[
      firstStarted.future,
      secondStarted.future,
    ]);
    return requests;
  }

  test('load uses authoritative page and count for content and badge',
      () async {
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

  test('refresh failure retains loaded favorites and allows pagination',
      () async {
    final firstItem = favoriteItem();
    final secondItem = favoriteItem(
      id: '40000000-dddd-4000-8000-000000000004',
      menuItemId: otherFavoriteMenuItemId,
    );
    repository
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[firstItem],
        pageNumber: 1,
        totalPages: 2,
        totalCount: 2,
        hasNextPage: true,
      )
      ..currentCount = 2
      ..onGetPage = (pageNumber, _) async => pageNumber == 1
          ? repository.currentPage
          : favoritesPage(
              items: <FavoriteMenuItem>[secondItem],
              pageNumber: 2,
              totalPages: 2,
              totalCount: 2,
              hasPreviousPage: true,
            );

    await cubit.load();
    repository.error = const FailureException(Failure(FailureCode.network));

    await cubit.refresh();

    expect(cubit.state.status, FavoritesStatus.error);
    expect(cubit.state.items, <FavoriteMenuItem>[firstItem]);
    expect(cubit.state.failure?.code, FailureCode.network);

    repository.error = null;
    await cubit.loadNextPage();

    expect(cubit.state.status, FavoritesStatus.populated);
    expect(cubit.state.items, <FavoriteMenuItem>[firstItem, secondItem]);
    expect(cubit.state.pageNumber, 2);
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

    expect(
        await cubit.toggle(favoriteMenuItemId), FavoriteMutationResult.success);
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

    expect(
        await cubit.toggle(favoriteMenuItemId), FavoriteMutationResult.success);
    expect(repository.lastRemoved, favoriteMenuItemId);
    expect(cubit.state.status, FavoritesStatus.empty);
    expect(cubit.state.badgeCount, 0);
    expect(cubit.state.isFavorite(favoriteMenuItemId), isFalse);
  });

  test('duplicate concurrent toggles share one mutation', () async {
    final gate = Completer<FavoriteMenuItem>();
    repository
      ..statuses[favoriteMenuItemId] = false
      ..onAdd = (_) {
        return gate.future;
      }
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
        return reads == 1
            ? oldPage.future
            : Future<FavoritesPage>.value(
                favoritesPage(
                  items: <FavoriteMenuItem>[favoriteItem()],
                  totalCount: 1,
                ),
              );
      }
      ..currentCount = 1;

    final olderRefresh = cubit.refresh();
    expect(
        await cubit.toggle(favoriteMenuItemId), FavoriteMutationResult.success);
    oldPage.complete(favoritesPage());
    await olderRefresh;

    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(cubit.state.badgeCount, 1);
  });

  test('refresh invalidates a pending pagination response', () async {
    final oldSecondPage = Completer<FavoritesPage>();
    final secondPageStarted = Completer<void>();
    final refreshedItem = favoriteItem(
      id: '40000000-dddd-4000-8000-000000000004',
      menuItemId: otherFavoriteMenuItemId,
    );
    var firstPageReads = 0;
    repository
      ..currentCount = 1
      ..onGetPage = (pageNumber, _) {
        if (pageNumber == 2) {
          secondPageStarted.complete();
          return oldSecondPage.future;
        }
        firstPageReads++;
        return Future<FavoritesPage>.value(
          favoritesPage(
            items: <FavoriteMenuItem>[
              firstPageReads == 1 ? favoriteItem() : refreshedItem,
            ],
            totalCount: 1,
            totalPages: 2,
            hasNextPage: true,
          ),
        );
      };

    await cubit.load();
    final pagination = cubit.loadNextPage();
    await secondPageStarted.future;

    await cubit.refresh();
    oldSecondPage.complete(
      favoritesPage(
        pageNumber: 2,
        totalPages: 2,
        totalCount: 2,
        hasPreviousPage: true,
        items: <FavoriteMenuItem>[
          favoriteItem(
            id: '40000000-eeee-4000-8000-000000000005',
            menuItemId: favoriteMenuItemId,
          ),
        ],
      ),
    );
    await pagination;

    expect(cubit.state.items, <FavoriteMenuItem>[refreshedItem]);
    expect(cubit.state.pageNumber, 1);
    expect(cubit.state.loadingMore, isFalse);
  });

  test('authoritative page wins over an older IsFavorite response', () async {
    final oldStatus = Completer<bool>();
    final statusStarted = Completer<void>();
    repository
      ..onIsFavorite = (_) {
        statusStarted.complete();
        return oldStatus.future;
      }
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalCount: 1,
      )
      ..currentCount = 1;

    final lookup = cubit.ensureFavoriteStatus(favoriteMenuItemId);
    await statusStarted.future;
    await cubit.refresh();
    expect(cubit.state.isChecking(favoriteMenuItemId), isFalse);

    oldStatus.complete(false);
    await lookup;

    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(cubit.state.isChecking(favoriteMenuItemId), isFalse);
  });

  test('concurrent membership successes preserve indicators in either order',
      () async {
    final firstResult = Completer<bool>();
    final secondResult = Completer<bool>();
    final requests = await startConcurrentStatusLookups(
      firstResult: firstResult,
      secondResult: secondResult,
    );

    expect(cubit.state.isChecking(favoriteMenuItemId), isTrue);
    expect(cubit.state.isChecking(otherFavoriteMenuItemId), isTrue);
    secondResult.complete(true);
    await requests[1];
    expect(cubit.state.isChecking(favoriteMenuItemId), isTrue);
    expect(cubit.state.isChecking(otherFavoriteMenuItemId), isFalse);

    firstResult.complete(false);
    await requests[0];
    expect(cubit.state.isChecking(favoriteMenuItemId), isFalse);
    expect(cubit.state.isChecking(otherFavoriteMenuItemId), isFalse);

    final thirdResult = Completer<bool>();
    final fourthResult = Completer<bool>();
    const thirdMenuItemId = '50000000-aaaa-4000-8000-000000000006';
    const fourthMenuItemId = '50000000-bbbb-4000-8000-000000000007';
    final reverseRequests = await startConcurrentStatusLookups(
      firstResult: thirdResult,
      secondResult: fourthResult,
      firstMenuItemId: thirdMenuItemId,
      secondMenuItemId: fourthMenuItemId,
    );
    thirdResult.complete(true);
    await reverseRequests[0];
    expect(cubit.state.isChecking(thirdMenuItemId), isFalse);
    expect(cubit.state.isChecking(fourthMenuItemId), isTrue);

    fourthResult.complete(false);
    await reverseRequests[1];
    expect(cubit.state.isChecking(thirdMenuItemId), isFalse);
    expect(cubit.state.isChecking(fourthMenuItemId), isFalse);
  });

  test('membership success does not clear another pending failed lookup',
      () async {
    final successfulResult = Completer<bool>();
    final failingResult = Completer<bool>();
    final requests = await startConcurrentStatusLookups(
      firstResult: successfulResult,
      secondResult: failingResult,
    );

    successfulResult.complete(true);
    await requests[0];
    expect(cubit.state.isChecking(favoriteMenuItemId), isFalse);
    expect(cubit.state.isChecking(otherFavoriteMenuItemId), isTrue);

    failingResult.completeError(
      const FailureException(Failure(FailureCode.network)),
    );
    await requests[1];
    expect(cubit.state.isChecking(favoriteMenuItemId), isFalse);
    expect(cubit.state.isChecking(otherFavoriteMenuItemId), isFalse);
    expect(cubit.state.failure?.code, FailureCode.network);
  });

  test('membership failure does not re-add a completed lookup indicator',
      () async {
    final failingResult = Completer<bool>();
    final successfulResult = Completer<bool>();
    final requests = await startConcurrentStatusLookups(
      firstResult: failingResult,
      secondResult: successfulResult,
    );

    failingResult.completeError(
      const FailureException(Failure(FailureCode.network)),
    );
    await requests[0];
    expect(cubit.state.isChecking(favoriteMenuItemId), isFalse);
    expect(cubit.state.isChecking(otherFavoriteMenuItemId), isTrue);

    successfulResult.complete(true);
    await requests[1];
    expect(cubit.state.isChecking(favoriteMenuItemId), isFalse);
    expect(cubit.state.isChecking(otherFavoriteMenuItemId), isFalse);
    expect(cubit.state.failure, isNull);
  });

  test('failed mutation discards pending pagination without stuck loading',
      () async {
    final oldSecondPage = Completer<FavoritesPage>();
    final secondPageStarted = Completer<void>();
    final mutation = Completer<void>();
    final mutationStarted = Completer<void>();
    final firstItem = favoriteItem();
    repository
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[firstItem],
        totalCount: 2,
        totalPages: 2,
        hasNextPage: true,
      )
      ..currentCount = 2
      ..onGetPage = (pageNumber, _) {
        if (pageNumber == 2) {
          secondPageStarted.complete();
          return oldSecondPage.future;
        }
        return Future<FavoritesPage>.value(repository.currentPage);
      }
      ..onRemove = (_) {
        mutationStarted.complete();
        return mutation.future;
      };

    await cubit.load();
    final pagination = cubit.loadNextPage();
    await secondPageStarted.future;
    final toggle = cubit.toggle(favoriteMenuItemId);
    await mutationStarted.future;

    expect(cubit.state.loadingMore, isFalse);
    mutation.completeError(
      const FailureException(Failure(FailureCode.network)),
    );
    expect(await toggle, FavoriteMutationResult.failed);

    oldSecondPage.complete(
      favoritesPage(
        pageNumber: 2,
        totalPages: 2,
        totalCount: 2,
        hasPreviousPage: true,
        items: <FavoriteMenuItem>[
          favoriteItem(
            id: '40000000-eeee-4000-8000-000000000005',
            menuItemId: otherFavoriteMenuItemId,
          ),
        ],
      ),
    );
    await pagination;

    expect(cubit.state.items, <FavoriteMenuItem>[firstItem]);
    expect(cubit.state.pageNumber, 1);
    expect(cubit.state.hasNextPage, isTrue);
    expect(cubit.state.loadingMore, isFalse);
    expect(cubit.state.isMutating, isFalse);
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
