import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/favorite_menu_item.dart';
import '../../domain/entities/favorites_cache_snapshot.dart';
import '../../domain/entities/favorites_page.dart';
import '../../domain/queries/favorite_identifiers.dart';
import '../../domain/queries/favorite_paging.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/usecases/add_to_favorites_use_case.dart';
import '../../domain/usecases/get_my_favorites_use_case.dart';
import '../../domain/usecases/remove_from_favorites_use_case.dart';
import 'favorites_state.dart';

enum FavoriteMutationResult { success, busy, failed, synchronizationFailed }

/// One authenticated-shell owner for all Favorites projections and membership.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({
    required AddToFavoritesUseCase addToFavoritesUseCase,
    required RemoveFromFavoritesUseCase removeFromFavoritesUseCase,
    required GetMyFavoritesUseCase getMyFavoritesUseCase,
    required FavoritePaging paging,
    required FavoritesRepository repository,
    required Future<String?> Function() getAuthenticatedUserId,
  })  : _add = addToFavoritesUseCase,
        _remove = removeFromFavoritesUseCase,
        _getPage = getMyFavoritesUseCase,
        _paging = paging,
        _repository = repository,
        _getAuthenticatedUserId = getAuthenticatedUserId,
        super(FavoritesState());

  final AddToFavoritesUseCase _add;
  final RemoveFromFavoritesUseCase _remove;
  final GetMyFavoritesUseCase _getPage;
  final FavoritePaging _paging;
  final FavoritesRepository _repository;
  final Future<String?> Function() _getAuthenticatedUserId;

  static const Duration freshnessWindow = Duration(minutes: 15);
  static const int _maxCachedIds = 5000;

  String? _userId;
  int _sessionEpoch = 0;
  bool _started = false;
  bool _refreshing = false;
  Future<void>? _refreshTask;
  Future<void> _cacheWriteQueue = Future<void>.value();
  bool _mutating = false;
  bool _decisionPending = false;
  int _snapshotVersion = 0;
  int _paginationVersion = 0;
  final Map<String, Future<FavoriteMutationResult>> _toggleRequests = {};

  Future<void> load() async {
    if (isClosed) return;
    final userId = await _readAuthenticatedUserId();
    if (isClosed) return;
    if (userId == null || userId.isEmpty) {
      if (_userId != null) _switchSession(null);
      _started = false;
      return;
    }
    if (_userId != userId) {
      _switchSession(userId, emitReset: _userId != null, reload: false);
    }
    if (_started) return;
    _started = true;
    final sessionEpoch = _sessionEpoch;
    FavoritesCacheSnapshot? cached;
    try {
      cached = await _repository.readCache(userId);
    } catch (_) {
      cached = null;
    }
    if (!await _validateSession(userId, sessionEpoch)) return;
    if (cached != null) _restore(cached);
    if (cached != null && cached.indexComplete && _isFresh(cached.savedAt)) {
      return;
    }
    if (cached == null) {
      await _refresh(showLoading: true);
    } else {
      unawaited(_refresh(showLoading: false));
    }
  }

  Future<void> refresh() async {
    if (!await _validateActiveSession()) return;
    await _refresh(showLoading: state.items.isEmpty, reportFailure: true);
  }

  Future<void> refreshIfStale() async {
    if (!await _validateActiveSession()) return;
    if (state.cacheTimestamp != null && _isFresh(state.cacheTimestamp!)) return;
    await _refresh(showLoading: false);
  }

  Future<bool> ensureFavoriteStatus(String menuItemId) async {
    // Kept as a compatibility entry point. Membership comes only from the
    // complete page index; this never performs an item-level request.
    if (!await _validateActiveSession()) return false;
    if (state.indexComplete) return true;
    await _refresh(showLoading: false);
    return state.indexComplete;
  }

  Future<FavoriteMutationResult> toggle(String menuItemId) {
    final id = menuItemId.trim();
    if (!isFavoriteMenuItemId(id)) {
      return Future.value(FavoriteMutationResult.failed);
    }
    final key = id.toLowerCase();
    final pending = _toggleRequests[key];
    if (pending != null) return pending;
    late final Future<FavoriteMutationResult> request;
    request = _toggle(id).whenComplete(() {
      if (identical(_toggleRequests[key], request)) _toggleRequests.remove(key);
    });
    _toggleRequests[key] = request;
    return request;
  }

  Future<void> loadNextPage() => _loadNextPage();
  Future<void> retryNextPage() => _loadNextPage(retry: true);

  Future<void> _refresh({
    required bool showLoading,
    bool reportFailure = false,
  }) {
    if (isClosed || (_mutating && !_decisionPending) || _userId == null) {
      return Future<void>.value();
    }
    final userId = _userId!;
    final sessionEpoch = _sessionEpoch;
    final active = _refreshTask;
    if (active != null) return active;
    final task = _performRefresh(
      showLoading: showLoading,
      reportFailure: reportFailure,
      userId: userId,
      sessionEpoch: sessionEpoch,
    );
    _refreshTask = task;
    return task.whenComplete(() {
      if (identical(_refreshTask, task)) _refreshTask = null;
    });
  }

  Future<void> _performRefresh({
    required bool showLoading,
    required bool reportFailure,
    required String userId,
    required int sessionEpoch,
  }) async {
    if (_refreshing) return;
    _refreshing = true;
    final version = _snapshotVersion;
    final requestVersion = ++_paginationVersion;
    if (showLoading && state.items.isEmpty) {
      emit(state.copyWith(status: FavoritesStatus.loading, loadingMore: false));
    }
    try {
      final pageMetadata = <_FavoritePageMetadata>[];
      final ids = <String>{};
      final visibleIds = <String>{
        ...state.items.map((item) => item.menuItemId.toLowerCase()),
      };
      final refreshedVisibleItems = <String, FavoriteMenuItem>{};
      var page = await _getPage(
        pageNumber: _paging.firstPage,
        pageSize: _paging.pageSize,
      );
      if (!await _validateSession(userId, sessionEpoch)) return;
      if (page.pageNumber != _paging.firstPage) {
        _refreshFailure(
          const Failure(FailureCode.validation, debugMessage: 'Unexpected favorite page number'),
          version,
          reportFailure: reportFailure,
        );
        return;
      }
      pageMetadata.add(_FavoritePageMetadata.fromPage(page));
      ids.addAll(page.items.map((item) => item.menuItemId.toLowerCase()));
      final firstPage = page;
      for (final item in page.items) {
        final key = item.menuItemId.toLowerCase();
        visibleIds.add(key);
        refreshedVisibleItems[key] = item;
      }
      // Publish first-page content immediately on a cold start. Unknown IDs
      // remain unknown until every server page has been collected.
      if (state.items.isEmpty && version == _snapshotVersion && !isClosed) {
        _emitPage(page, indexComplete: false);
      }
      var nextPage = page.pageNumber + 1;
      var hasNext = page.hasNextPage && nextPage <= page.totalPages;
      while (hasNext) {
        if (isClosed || version != _snapshotVersion ||
            requestVersion != _paginationVersion) return;
        page = await _getPage(pageNumber: nextPage, pageSize: _paging.pageSize);
        if (!await _validateSession(userId, sessionEpoch)) return;
        if (page.pageNumber != nextPage) {
          _refreshFailure(
            const Failure(FailureCode.validation, debugMessage: 'Unexpected favorite page number'),
            version,
            reportFailure: reportFailure,
          );
          return;
        }
        pageMetadata.add(_FavoritePageMetadata.fromPage(page));
        ids.addAll(page.items.map((item) => item.menuItemId.toLowerCase()));
        for (final item in page.items) {
          final key = item.menuItemId.toLowerCase();
          if (visibleIds.contains(key)) refreshedVisibleItems[key] = item;
        }
        nextPage = page.pageNumber + 1;
        hasNext = page.hasNextPage && nextPage <= page.totalPages;
      }
      if (hasNext || isClosed || version != _snapshotVersion ||
          requestVersion != _paginationVersion) return;
      final firstMetadata = pageMetadata.first;
      final emptyResult = pageMetadata.length == 1 &&
          firstMetadata.totalCount == 0 && !firstMetadata.hasNextPage;
      if (ids.length != firstMetadata.totalCount ||
          (!emptyResult && pageMetadata.last.pageNumber != firstMetadata.totalPages) ||
          pageMetadata.asMap().entries.any((entry) =>
              entry.value.pageNumber != firstMetadata.pageNumber + entry.key) ||
          pageMetadata.any((value) =>
              value.totalCount != firstMetadata.totalCount ||
              value.totalPages != firstMetadata.totalPages)) {
        return;
      }
      // Count is taken from the same page snapshot; GetCount is redundant.
      final displayItems = _deduplicate(<FavoriteMenuItem>[
        ...firstPage.items,
        ...state.items
            .where((item) => ids.contains(item.menuItemId.toLowerCase()))
            .map((item) => refreshedVisibleItems[item.menuItemId.toLowerCase()] ?? item),
      ]);
      final displayPage = pageMetadata.firstWhere(
        (value) => value.pageNumber == (state.pageNumber ?? _paging.firstPage),
        orElse: () => firstMetadata,
      );
      emit(FavoritesState(
        status: displayItems.isEmpty ? FavoritesStatus.empty : FavoritesStatus.populated,
        items: displayItems,
        favoriteByMenuItemId: <String, bool>{for (final id in ids) id: true},
        pageNumber: displayPage.pageNumber,
        totalPages: displayPage.totalPages,
        totalCount: firstMetadata.totalCount,
        hasPreviousPage: displayPage.hasPreviousPage,
        hasNextPage: displayPage.hasNextPage,
        indexComplete: true,
        cacheTimestamp: DateTime.now().toUtc(),
        isMutating: _mutating,
      ));
      await _persist(userId, sessionEpoch);
    } on FailureException catch (error) {
      if (await _validateSession(userId, sessionEpoch)) {
        _refreshFailure(error.failure, version, reportFailure: reportFailure);
      }
    } catch (error) {
      if (await _validateSession(userId, sessionEpoch)) {
        _refreshFailure(
          Failure(FailureCode.unknown, debugMessage: error.toString()),
          version,
          reportFailure: reportFailure,
        );
      }
    } finally {
      if (sessionEpoch == _sessionEpoch) _refreshing = false;
    }
  }

  Future<FavoriteMutationResult> _toggle(String menuItemId) async {
    if (isClosed || _mutating) return FavoriteMutationResult.busy;
    if (!await _validateActiveSession()) return FavoriteMutationResult.busy;
    final userId = _userId!;
    final sessionEpoch = _sessionEpoch;
    _mutating = true;
    _decisionPending = true;
    emit(state.copyWith(isMutating: true));
    if (!state.indexComplete) {
      await _refresh(showLoading: false);
      if (!await _validateSession(userId, sessionEpoch) ||
          !state.indexComplete || isClosed) {
        if (sessionEpoch == _sessionEpoch) {
          _mutating = false;
          _decisionPending = false;
          if (!isClosed) emit(state.copyWith(isMutating: false));
        }
        return FavoriteMutationResult.failed;
      }
    }
    _decisionPending = false;
    final key = menuItemId.toLowerCase();
    final before = state;
    final wasFavorite = before.isFavorite(key);
    _snapshotVersion++;
    _paginationVersion++;
    final updatedIds = <String, bool>{...before.favoriteByMenuItemId};
    final updatedItems = <FavoriteMenuItem>[...before.items];
    var count = before.totalCount;
    if (wasFavorite) {
      updatedIds.remove(key);
      updatedItems.removeWhere((item) => item.menuItemId.toLowerCase() == key);
      count = count > 0 ? count - 1 : 0;
    } else {
      updatedIds[key] = true;
      count++;
    }
    _emitMutationState(updatedItems, updatedIds, count, before);
    try {
      if (!await _validateSession(userId, sessionEpoch)) {
        return FavoriteMutationResult.busy;
      }
      if (wasFavorite) {
        final removedId = await _remove(menuItemId);
        if (!await _validateSession(userId, sessionEpoch)) {
          return FavoriteMutationResult.busy;
        }
        if (removedId.toLowerCase() != key) {
          throw const FailureException(Failure(
            FailureCode.validation,
            debugMessage: 'Favorite removal response did not match requested item',
          ));
        }
      } else {
        final item = await _add(menuItemId);
        if (!await _validateSession(userId, sessionEpoch)) {
          return FavoriteMutationResult.busy;
        }
        if (item.menuItemId.toLowerCase() != key) {
          throw const FailureException(Failure(
            FailureCode.validation,
            debugMessage: 'Favorite response did not match requested item',
          ));
        }
        final items = <FavoriteMenuItem>[
          item,
          ...state.items.where((value) => value.menuItemId.toLowerCase() != key),
        ];
        if (items.length > _paging.pageSize) items.removeLast();
        _emitMutationState(items, state.favoriteByMenuItemId, state.totalCount, before);
      }
      await _persist(userId, sessionEpoch);
      return FavoriteMutationResult.success;
    } catch (error) {
      if (!await _validateSession(userId, sessionEpoch)) {
        return FavoriteMutationResult.busy;
      }
      // Global mutation lock prevents a later tap from being overwritten by
      // this rollback. Invalidate any in-flight refresh snapshot as well.
      _snapshotVersion++;
      if (!isClosed) {
        emit(FavoritesState(
          status: before.status,
          items: before.items,
          favoriteByMenuItemId: before.favoriteByMenuItemId,
          pageNumber: before.pageNumber,
          totalPages: before.totalPages,
          totalCount: before.totalCount,
          hasPreviousPage: before.hasPreviousPage,
          hasNextPage: before.hasNextPage,
          indexComplete: before.indexComplete,
          cacheTimestamp: null,
          failure: error is FailureException
              ? error.failure
              : Failure(FailureCode.unknown, debugMessage: error.toString()),
        ));
      }
      // One deferred reconciliation handles uncertain network outcomes.
      scheduleMicrotask(() => unawaited(_refresh(showLoading: false)));
      return FavoriteMutationResult.failed;
    } finally {
      if (sessionEpoch == _sessionEpoch &&
          await _validateSession(userId, sessionEpoch)) {
        _mutating = false;
        _decisionPending = false;
        if (!isClosed) emit(state.copyWith(isMutating: false));
      }
    }
  }

  void _emitMutationState(
    List<FavoriteMenuItem> items,
    Map<String, bool> ids,
    int count,
    FavoritesState previous,
  ) {
    emit(FavoritesState(
      status: items.isEmpty && count == 0 ? FavoritesStatus.empty : FavoritesStatus.populated,
      items: items,
      favoriteByMenuItemId: ids,
      pageNumber: previous.pageNumber ?? _paging.firstPage,
      totalPages: previous.totalPages,
      totalCount: count,
      hasPreviousPage: previous.hasPreviousPage,
      hasNextPage: previous.hasNextPage,
      indexComplete: previous.indexComplete,
      cacheTimestamp: DateTime.now().toUtc(),
      isMutating: true,
    ));
  }

  Future<void> _loadNextPage({bool retry = false}) async {
    if (!await _validateActiveSession()) return;
    final current = state;
    if (isClosed || _mutating || current.loadingMore || !current.hasNextPage ||
        current.pageNumber == null || !current.indexComplete ||
        (!retry && current.nextPageFailure != null)) return;
    final version = ++_paginationVersion;
    final userId = _userId!;
    final sessionEpoch = _sessionEpoch;
    emit(current.copyWith(loadingMore: true, clearNextPageFailure: true));
    try {
      final page = await _getPage(
        pageNumber: current.pageNumber! + 1,
        pageSize: _paging.pageSize,
      );
      if (!await _validateSession(userId, sessionEpoch) ||
          isClosed || version != _paginationVersion) return;
      final items = _deduplicate(<FavoriteMenuItem>[...state.items, ...page.items]);
      final ids = <String, bool>{...state.favoriteByMenuItemId};
      for (final item in page.items) ids[item.menuItemId.toLowerCase()] = true;
      emit(FavoritesState(
        status: items.isEmpty ? FavoritesStatus.empty : FavoritesStatus.populated,
        items: items,
        favoriteByMenuItemId: ids,
        pageNumber: page.pageNumber,
        totalPages: page.totalPages,
        totalCount: state.totalCount,
        hasPreviousPage: page.hasPreviousPage,
        hasNextPage: page.hasNextPage,
        indexComplete: true,
        cacheTimestamp: state.cacheTimestamp,
      ));
      await _persist(userId, sessionEpoch);
    } on FailureException catch (error) {
      if (await _validateSession(userId, sessionEpoch) &&
          !isClosed && version == _paginationVersion) {
        emit(state.copyWith(loadingMore: false, nextPageFailure: error.failure));
      }
    } catch (_) {
      if (await _validateSession(userId, sessionEpoch) &&
          !isClosed && version == _paginationVersion) {
        emit(state.copyWith(loadingMore: false, nextPageFailure: const Failure(FailureCode.unknown)));
      }
    }
  }

  void _restore(FavoritesCacheSnapshot cache) {
    final membership = <String, bool>{for (final id in cache.favoriteIds) id: true};
    emit(FavoritesState(
      status: cache.items.isEmpty
          ? cache.totalCount == 0 ? FavoritesStatus.empty : FavoritesStatus.populated
          : FavoritesStatus.populated,
      items: cache.items,
      favoriteByMenuItemId: membership,
      totalCount: cache.totalCount,
      pageNumber: cache.pageNumber,
      totalPages: cache.totalPages,
      hasNextPage: cache.hasNextPage,
      hasPreviousPage: cache.hasPreviousPage,
      indexComplete: cache.indexComplete,
      cacheTimestamp: cache.savedAt,
    ));
  }

  void _emitPage(FavoritesPage page, {required bool indexComplete}) {
    emit(FavoritesState(
      status: page.items.isEmpty ? FavoritesStatus.empty : FavoritesStatus.populated,
      items: page.items,
      favoriteByMenuItemId: <String, bool>{
        for (final item in page.items) item.menuItemId.toLowerCase(): true,
      },
      pageNumber: page.pageNumber,
      totalPages: page.totalPages,
      totalCount: page.totalCount,
      hasPreviousPage: page.hasPreviousPage,
      hasNextPage: page.hasNextPage,
      indexComplete: indexComplete,
      isMutating: _mutating,
    ));
  }

  void _refreshFailure(
    Failure failure,
    int version, {
    required bool reportFailure,
  }) {
    if (isClosed || version != _snapshotVersion) return;
    if (reportFailure ||
        (state.items.isEmpty &&
            state.status == FavoritesStatus.loading &&
            state.cacheTimestamp == null)) {
      emit(state.copyWith(status: FavoritesStatus.error, failure: failure));
    }
    // A stale/background refresh failure never replaces valid cached content.
  }

  Future<void> _persist(String userId, int sessionEpoch) async {
    if (!state.indexComplete ||
        !await _validateSession(userId, sessionEpoch) ||
        isClosed) return;
    final cachedIds = <String>{
      ...state.items
          .take(_paging.pageSize)
          .map((item) => item.menuItemId.toLowerCase()),
      ...state.favoriteByMenuItemId.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key),
    }.take(_maxCachedIds);
    final snapshot = FavoritesCacheSnapshot(
        favoriteIds: cachedIds,
        items: state.items.take(_paging.pageSize).toList(growable: false),
        totalCount: state.totalCount,
        pageNumber: _paging.firstPage,
        totalPages: state.totalPages,
        hasNextPage: state.totalPages > _paging.firstPage,
        hasPreviousPage: false,
        indexComplete: state.favoriteByMenuItemId.length <= _maxCachedIds &&
            state.favoriteByMenuItemId.length == state.totalCount,
        savedAt: DateTime.now().toUtc(),
      );
    final write = _cacheWriteQueue.then<void>(
      (_) async {
        if (isClosed ||
            sessionEpoch != _sessionEpoch ||
            _userId != userId ||
            !await _validateSession(userId, sessionEpoch) ||
            isClosed ||
            sessionEpoch != _sessionEpoch ||
            _userId != userId) {
          return;
        }
        await _repository.writeCache(userId, snapshot);
      },
    );
    _cacheWriteQueue = write.catchError((Object _) {});
    try {
      await write;
    } catch (_) {
      // A local storage failure must not roll back a confirmed remote mutation
      // or surface as a Favorites network error.
    }
  }

  bool _isFresh(DateTime timestamp) =>
      DateTime.now().toUtc().difference(timestamp.toUtc()) >= Duration.zero &&
      DateTime.now().toUtc().difference(timestamp.toUtc()) < freshnessWindow;

  List<FavoriteMenuItem> _deduplicate(Iterable<FavoriteMenuItem> items) =>
      <String, FavoriteMenuItem>{
        for (final item in items) item.menuItemId.toLowerCase(): item,
      }.values.toList(growable: false);

  Future<String?> _readAuthenticatedUserId() async {
    try {
      final userId = (await _getAuthenticatedUserId())?.trim();
      return userId == null || userId.isEmpty ? null : userId;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _validateActiveSession() async {
    if (isClosed) return false;
    final currentUserId = await _readAuthenticatedUserId();
    if (isClosed) return false;
    if (currentUserId == _userId && currentUserId != null) return true;
    _switchSession(currentUserId);
    return false;
  }

  Future<bool> _validateSession(String userId, int sessionEpoch) async {
    if (isClosed || sessionEpoch != _sessionEpoch || _userId != userId) {
      return false;
    }
    final currentUserId = await _readAuthenticatedUserId();
    if (isClosed || sessionEpoch != _sessionEpoch || _userId != userId) {
      return false;
    }
    if (currentUserId == userId) return true;
    _switchSession(currentUserId);
    return false;
  }

  void _switchSession(
    String? userId, {
    bool emitReset = true,
    bool reload = true,
  }) {
    if (isClosed || _userId == userId && _started == false) return;
    _sessionEpoch++;
    _snapshotVersion++;
    _paginationVersion++;
    _userId = userId;
    _started = false;
    _refreshing = false;
    _refreshTask = null;
    _mutating = false;
    _decisionPending = false;
    _toggleRequests.clear();
    if (emitReset) emit(FavoritesState());
    if (reload && userId != null) unawaited(load());
  }

  @override
  Future<void> close() {
    _sessionEpoch++;
    _snapshotVersion++;
    _paginationVersion++;
    _userId = null;
    _started = false;
    _refreshTask = null;
    _refreshing = false;
    _mutating = false;
    _decisionPending = false;
    _toggleRequests.clear();
    return super.close();
  }
}

class _FavoritePageMetadata {
  const _FavoritePageMetadata({
    required this.pageNumber,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory _FavoritePageMetadata.fromPage(FavoritesPage page) =>
      _FavoritePageMetadata(
        pageNumber: page.pageNumber,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        hasPreviousPage: page.hasPreviousPage,
        hasNextPage: page.hasNextPage,
      );

  final int pageNumber;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;
}
