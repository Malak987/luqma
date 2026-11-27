import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorite_menu_item.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorites_cache_snapshot.dart';
import 'package:luqma_app/features/favorites/domain/entities/favorites_page.dart';
import 'package:luqma_app/features/favorites/domain/queries/favorite_paging.dart';
import 'package:luqma_app/features/favorites/domain/usecases/add_to_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/get_my_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/domain/usecases/remove_from_favorites_use_case.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:luqma_app/features/favorites/presentation/cubit/favorites_state.dart';

import '../../support/favorite_fixtures.dart';

class _TestFavoritesRepository extends FakeFavoritesRepository {
  int writeCacheCalls = 0;
  Future<void> Function(String userId, FavoritesCacheSnapshot snapshot)? onWriteCache;

  @override
  Future<void> writeCache(String userId, FavoritesCacheSnapshot snapshot) async {
    writeCacheCalls++;
    cacheUserId = userId;
    cachedSnapshot = snapshot;
    if (onWriteCache != null) {
      await onWriteCache!(userId, snapshot);
    }
  }
}

void main() {
  late FakeFavoritesRepository repository;
  late FavoritesCubit cubit;

  setUp(() {
    repository = FakeFavoritesRepository();
    cubit = FavoritesCubit(
      addToFavoritesUseCase: AddToFavoritesUseCase(repository),
      removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repository),
      getMyFavoritesUseCase: GetMyFavoritesUseCase(repository),
      paging: const FavoritePaging(),
      repository: repository,
      getAuthenticatedUserId: () async => 'test-user',
    );
  });

  tearDown(() => cubit.close());

  test('loads page count and builds a complete index across all pages', () async {
    final second = favoriteItem(
      id: '40000000-dddd-4000-8000-000000000004',
      menuItemId: otherFavoriteMenuItemId,
    );
    repository
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalPages: 2,
        totalCount: 2,
        hasNextPage: true,
      )
      ..onGetPage = (page, _) async => page == 1
          ? repository.currentPage
          : favoritesPage(
              items: <FavoriteMenuItem>[second],
              pageNumber: 2,
              totalPages: 2,
              totalCount: 2,
              hasPreviousPage: true,
            );

    await cubit.load();

    expect(cubit.state.totalCount, 2);
    expect(cubit.state.indexComplete, isTrue);
    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(cubit.state.isFavorite(otherFavoriteMenuItemId), isTrue);
    expect(repository.pageReads, 2);
    expect(repository.countReads, 0);
  });

  test('pagination appends items once and reports page failures', () async {
    final second = favoriteItem(
      id: '40000000-dddd-4000-8000-000000000004',
      menuItemId: otherFavoriteMenuItemId,
    );
    final third = favoriteItem(
      id: '40000000-eeee-4000-8000-000000000005',
      menuItemId: '40000000-ffff-4000-8000-000000000006',
    );
    var pageThreeReads = 0;
    repository
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalPages: 3,
        totalCount: 3,
        hasNextPage: true,
      )
      ..onGetPage = (page, _) async {
        if (page == 1) return repository.currentPage;
        if (page == 3) {
          pageThreeReads++;
          if (pageThreeReads > 1) {
            throw const FailureException(Failure(FailureCode.network));
          }
          return favoritesPage(
            items: <FavoriteMenuItem>[third],
            pageNumber: 3,
            totalPages: 3,
            totalCount: 3,
            hasPreviousPage: true,
          );
        }
        if (page != 2) {
          throw const FailureException(Failure(FailureCode.network));
        }
        return favoritesPage(
          items: <FavoriteMenuItem>[second],
          pageNumber: 2,
          totalPages: 3,
          totalCount: 3,
          hasPreviousPage: true,
          hasNextPage: true,
        );
      };

    await cubit.load();
    await cubit.loadNextPage();
    expect(cubit.state.items.map((item) => item.menuItemId),
        <String>[favoriteMenuItemId, otherFavoriteMenuItemId]);
    expect(cubit.state.pageNumber, 2);

    await cubit.loadNextPage();
    expect(cubit.state.items.length, 2);
    expect(cubit.state.loadingMore, isFalse);
    expect(cubit.state.nextPageFailure?.code, FailureCode.network);
  });

  test('restores fresh account cache before making any remote request', () async {
    repository.cachedSnapshot = FavoritesCacheSnapshot(
      favoriteIds: <String>[favoriteMenuItemId],
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
      pageNumber: 1,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
      indexComplete: true,
      savedAt: DateTime.now().toUtc(),
    );

    await cubit.load();

    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(cubit.state.indexComplete, isTrue);
    expect(repository.cacheUserId, 'test-user');
    expect(repository.pageReads, 0);
  });

  test('membership checks and first load never call IsFavorite or GetCount',
      () async {
    repository.currentPage = favoritesPage(
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
    );

    await cubit.load();
    // Membership is answered locally from the loaded index: no IsFavorite and
    // no GetCount request is issued.
    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(cubit.state.knowsFavorite(favoriteMenuItemId), isTrue);

    expect(repository.lastIsFavorite, isNull);
    expect(repository.countReads, 0);
  });

  test('Add updates membership and count immediately without fabricating item',
      () async {
    repository.currentPage = favoritesPage();
    await cubit.load();
    final gate = Completer<FavoriteMenuItem>();
    repository.onAdd = (_) => gate.future;

    final mutation = cubit.toggle(favoriteMenuItemId);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(cubit.state.totalCount, 1);
    expect(cubit.state.items, isEmpty);
    gate.complete(favoriteItem());
    expect(await mutation, FavoriteMutationResult.success);
    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(repository.pageReads, 1);
    expect(repository.countReads, 0);
  });

  test('rapid duplicate taps share one Add request', () async {
    repository.currentPage = favoritesPage();
    await cubit.load();
    final gate = Completer<FavoriteMenuItem>();
    repository.onAdd = (_) => gate.future;

    final first = cubit.toggle(favoriteMenuItemId);
    final second = cubit.toggle(favoriteMenuItemId);
    await Future<void>.delayed(Duration.zero);
    expect(repository.addCalls, 1);
    gate.complete(favoriteItem());

    expect(await first, FavoriteMutationResult.success);
    expect(await second, FavoriteMutationResult.success);
    expect(repository.pageReads, 1);
    expect(repository.countReads, 0);
  });

  test('Remove immediately removes all projections and decrements once', () async {
    repository.currentPage = favoritesPage(
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
    );
    await cubit.load();
    final gate = Completer<void>();
    repository.onRemove = (_) => gate.future;

    final mutation = cubit.toggle(favoriteMenuItemId);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isFavorite(favoriteMenuItemId), isFalse);
    expect(cubit.state.totalCount, 0);
    expect(cubit.state.items, isEmpty);
    gate.complete();
    expect(await mutation, FavoriteMutationResult.success);
    expect(repository.pageReads, 1);
    expect(repository.countReads, 0);
  });

  test('failed mutation rolls back the local snapshot', () async {
    repository.currentPage = favoritesPage(
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
    );
    await cubit.load();
    repository.error = const FailureException(Failure(FailureCode.network));

    expect(await cubit.toggle(favoriteMenuItemId), FavoriteMutationResult.failed);
    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(cubit.state.totalCount, 1);
  });

  test('older refresh response cannot overwrite a successful mutation', () async {
    repository.currentPage = favoritesPage();
    await cubit.load();
    final oldPage = Completer<FavoritesPage>();
    repository.onGetPage = (_, __) => oldPage.future;
    final refresh = cubit.refresh();
    await Future<void>.delayed(Duration.zero);

    expect(await cubit.toggle(favoriteMenuItemId), FavoriteMutationResult.success);
    oldPage.complete(favoritesPage());
    await refresh;

    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(cubit.state.totalCount, 1);
  });

  test('unknown membership remains unknown when pagination is incomplete',
      () async {
    repository
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalPages: 2,
        totalCount: 2,
        hasNextPage: true,
      )
      ..onGetPage = (page, _) async {
        if (page == 1) return repository.currentPage;
        throw const FailureException(Failure(FailureCode.network));
      };

    await cubit.load();

    expect(cubit.state.indexComplete, isFalse);
    expect(cubit.state.knowsFavorite(otherFavoriteMenuItemId), isFalse);
    expect(repository.lastIsFavorite, isNull);
  });

  test('pagination failure keeps the last complete cached snapshot', () async {
    repository.cachedSnapshot = FavoritesCacheSnapshot(
      favoriteIds: <String>[favoriteMenuItemId],
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
      pageNumber: 1,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
      indexComplete: true,
      savedAt: DateTime.utc(2020),
    );
    repository.onGetPage = (_, __) async =>
        throw const FailureException(Failure(FailureCode.network));

    await cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(cubit.state.isFavorite(favoriteMenuItemId), isTrue);
    expect(cubit.state.indexComplete, isTrue);
  });

  test('manual refresh failure retains content and reports an actionable error',
      () async {
    repository.currentPage = favoritesPage(
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
    );
    await cubit.load();
    repository.error = const FailureException(Failure(FailureCode.network));

    await cubit.refresh();

    expect(cubit.state.status, FavoritesStatus.error);
    expect(cubit.state.items.single.menuItemId, favoriteMenuItemId);
    expect(cubit.state.failure?.code, FailureCode.network);
  });

  test('closing during a request prevents late state emissions', () async {
    final page = Completer<FavoritesPage>();
    final started = Completer<void>();
    repository.onGetPage = (_, __) {
      started.complete();
      return page.future;
    };
    final states = <FavoritesState>[];
    final subscription = cubit.stream.listen(states.add);
    final load = cubit.load();
    await started.future;
    await cubit.close();
    final countAtClose = states.length;

    page.complete(favoritesPage());
    await load;

    expect(states.length, countAtClose);
    await subscription.cancel();
  });

  test('account switching during in-flight load discards old session data', () async {
    var userId = 'user-a';
    final userAPage = Completer<FavoritesPage>();
    final userBPage = Completer<FavoritesPage>();

    final userACubit = FavoritesCubit(
      addToFavoritesUseCase: AddToFavoritesUseCase(repository),
      removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repository),
      getMyFavoritesUseCase: GetMyFavoritesUseCase(repository),
      paging: const FavoritePaging(),
      repository: repository,
      getAuthenticatedUserId: () async => userId,
    );
    addTearDown(userACubit.close);

    repository.onGetPage = (page, _) async {
      if (userId == 'user-a') return userAPage.future;
      return userBPage.future;
    };

    final loadFuture = userACubit.load();
    await Future<void>.delayed(Duration.zero);

    userId = 'user-b';
    await userACubit.refresh(); // Triggers session switch to user-b

    userAPage.complete(favoritesPage(
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
    ));
    await loadFuture;

    expect(userACubit.state.items, isEmpty);
  });

  test('logout during in-flight load resets state to initial empty', () async {
    String? userId = 'user-a';
    final pendingPage = Completer<FavoritesPage>();

    final authCubit = FavoritesCubit(
      addToFavoritesUseCase: AddToFavoritesUseCase(repository),
      removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(repository),
      getMyFavoritesUseCase: GetMyFavoritesUseCase(repository),
      paging: const FavoritePaging(),
      repository: repository,
      getAuthenticatedUserId: () async => userId,
    );
    addTearDown(authCubit.close);

    repository.onGetPage = (_, __) => pendingPage.future;

    final loadFuture = authCubit.load();
    await Future<void>.delayed(Duration.zero);

    userId = null;
    await authCubit.load(); // Triggers session switch to null

    pendingPage.complete(favoritesPage(
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
    ));
    await loadFuture;

    expect(authCubit.state.items, isEmpty);
    expect(authCubit.state.totalCount, 0);
  });

  test('queued cache write is aborted if cubit closes before invocation', () async {
    final testRepository = _TestFavoritesRepository();
    final testCubit = FavoritesCubit(
      addToFavoritesUseCase: AddToFavoritesUseCase(testRepository),
      removeFromFavoritesUseCase: RemoveFromFavoritesUseCase(testRepository),
      getMyFavoritesUseCase: GetMyFavoritesUseCase(testRepository),
      paging: const FavoritePaging(),
      repository: testRepository,
      getAuthenticatedUserId: () async => 'test-user',
    );

    final secondItem = favoriteItem(
      id: '40000000-dddd-4000-8000-000000000004',
      menuItemId: otherFavoriteMenuItemId,
    );

    testRepository
      ..currentPage = favoritesPage(
        items: <FavoriteMenuItem>[favoriteItem()],
        totalPages: 2,
        totalCount: 2,
        hasNextPage: true,
      )
      ..onGetPage = (page, _) async => page == 1
          ? testRepository.currentPage
          : favoritesPage(
              items: <FavoriteMenuItem>[secondItem],
              pageNumber: 2,
              totalPages: 2,
              totalCount: 2,
              hasPreviousPage: true,
            );

    final firstWriteStarted = Completer<void>();
    final firstWriteGate = Completer<void>();

    testRepository.onWriteCache = (userId, snapshot) {
      if (testRepository.writeCacheCalls == 1) {
        firstWriteStarted.complete();
        return firstWriteGate.future;
      }
      return Future<void>.value();
    };

    final loadTask = testCubit.load();
    await firstWriteStarted.future;
    expect(testRepository.writeCacheCalls, 1);

    final nextPageTask = testCubit.loadNextPage();
    await testCubit.stream.firstWhere((state) => state.items.length == 2);
    await Future<void>.delayed(Duration.zero);

    await testCubit.close();

    firstWriteGate.complete();

    await loadTask;
    await nextPageTask;

    expect(testRepository.writeCacheCalls, 1);
  });

  test('5,001 items build complete in-memory index but mark disk cache incomplete', () async {
    final items = List<FavoriteMenuItem>.generate(
      5001,
      (index) => favoriteItem(
        id: '40000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
        menuItemId: '40000000-1111-4000-8000-${index.toString().padLeft(12, '0')}',
      ),
    );

    repository
      ..currentPage = favoritesPage(
        items: items.take(20).toList(),
        totalPages: 1,
        totalCount: 5001,
        hasNextPage: false,
      )
      ..onGetPage = (_, __) async => favoritesPage(
            items: items,
            totalPages: 1,
            totalCount: 5001,
            hasNextPage: false,
          );

    await cubit.load();

    expect(cubit.state.totalCount, 5001);
    expect(cubit.state.favoriteIds.length, 5001);
    expect(cubit.state.indexComplete, isTrue);

    expect(repository.cachedSnapshot, isNotNull);
    expect(repository.cachedSnapshot!.favoriteIds.length, 5000);
    expect(repository.cachedSnapshot!.indexComplete, isFalse);
  });

  test('different item mutation during active mutation returns busy', () async {
    repository.currentPage = favoritesPage(
      items: <FavoriteMenuItem>[favoriteItem()],
      totalCount: 1,
    );
    await cubit.load();

    final pendingAdd = Completer<FavoriteMenuItem>();
    repository.onAdd = (_) => pendingAdd.future;

    final first = cubit.toggle(otherFavoriteMenuItemId);
    await Future<void>.delayed(Duration.zero);

    final second = cubit.toggle(favoriteMenuItemId);
    expect(await second, FavoriteMutationResult.busy);

    pendingAdd.complete(favoriteItem(menuItemId: otherFavoriteMenuItemId));
    expect(await first, FavoriteMutationResult.success);
  });
}
