import 'dart:async';
import 'dart:math' as math;

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

/// `busy` means "nothing to report": the tap was merged into a toggle that is
/// already on its way, and that toggle's own future reports the outcome.
enum FavoriteMutationResult { success, busy, failed }

/// One authenticated-shell owner for all Favorites data and every heart.
///
/// * Hearts flip instantly (optimistic) and roll back if the server refuses.
/// * Every item has its own tiny job; nothing is globally locked, so two
///   different hearts can be toggled at the same time.
/// * Rapid taps on one heart collapse into the final desired state.
/// * The membership index is built from the server pages fetched in
///   parallel (not one after another) and cached per account, so a fresh
///   cache means zero requests at startup.
/// * The account is read once, at [load]. The cubit is owned by the
///   authenticated shell and is closed on logout, which is what keeps one
///   account's data from reaching another (`isClosed` guards every await).
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
        super(const FavoritesState());

  final AddToFavoritesUseCase _add;
  final RemoveFromFavoritesUseCase _remove;
  final GetMyFavoritesUseCase _getPage;
  final FavoritePaging _paging;
  final FavoritesRepository _repository;
  final Future<String?> Function() _getAuthenticatedUserId;

  static const Duration freshnessWindow = Duration(minutes: 15);
  static const Duration _persistDelay = Duration(milliseconds: 800);
  static const Duration _refreshDelay = Duration(milliseconds: 600);
  static const int _maxCachedIds = 5000;

  /// Pages requested at the same time while building the index.
  static const int _parallelPages = 6;

  String? _userId;
  bool _started = false;
  bool _persistDirty = false;

  /// Bumped whenever a toggle starts or settles; a refresh that overlapped
  /// one is discarded and re-run so it can never undo a confirmed change.
  int _version = 0;

  /// Bumped when the list is replaced; invalidates an in-flight "load more".
  int _pageEpoch = 0;
  Future<void>? _refreshTask;
  Timer? _persistTimer;
  Timer? _refreshTimer;
  final Map<String, _ToggleJob> _jobs = <String, _ToggleJob>{};

  // ---------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------

  Future<void> load() async {
    if (isClosed || _started) return;
    _started = true;
    final userId = await _readUserId();
    if (isClosed) return;
    if (userId == null) {
      _started = false;
      return;
    }
    _userId = userId;

    FavoritesCacheSnapshot? cached;
    try {
      cached = await _repository.readCache(userId);
    } catch (_) {
      cached = null;
    }
    if (isClosed) return;

    if (cached == null) {
      await _refresh(showLoading: true);
      return;
    }
    _restore(cached);
    // A complete, fresh cache needs no network at all.
    if (cached.indexComplete && _isFresh(cached.savedAt)) return;
    unawaited(_refresh(showLoading: false));
  }

  Future<void> refresh() async {
    if (!await _ensureStarted()) return;
    await _refresh(showLoading: state.items.isEmpty, reportFailure: true);
  }

  Future<void> refreshIfStale() async {
    if (!await _ensureStarted()) return;
    final timestamp = state.cacheTimestamp;
    if (timestamp != null && _isFresh(timestamp)) return;
    await _refresh(showLoading: false);
  }

  Future<bool> _ensureStarted() async {
    if (isClosed) return false;
    if (_userId == null) await load();
    return !isClosed && _userId != null;
  }

  Future<void> _refresh({
    required bool showLoading,
    bool reportFailure = false,
  }) {
    if (isClosed || _userId == null) return Future<void>.value();
    final active = _refreshTask;
    if (active != null) return active;
    final task = _performRefresh(
      showLoading: showLoading,
      reportFailure: reportFailure,
    );
    _refreshTask = task;
    return task.whenComplete(() {
      if (identical(_refreshTask, task)) _refreshTask = null;
    });
  }

  Future<void> _performRefresh({
    required bool showLoading,
    required bool reportFailure,
  }) async {
    final version = _version;
    final firstNumber = _paging.firstPage;
    if (showLoading && state.items.isEmpty) {
      emit(
        state.copyWith(
          status: FavoritesStatus.loading,
          loadingMore: false,
          clearFailure: true,
        ),
      );
    }
    try {
      final first = await _getPage(
        pageNumber: firstNumber,
        pageSize: _paging.pageSize,
      );
      if (isClosed) return;
      if (first.pageNumber != firstNumber) {
        throw const FailureException(
          Failure(
            FailureCode.validation,
            debugMessage: 'Unexpected favorite page number',
          ),
        );
      }
      // Cold start: paint the first page right away while the rest loads.
      if (state.items.isEmpty && _jobs.isEmpty && version == _version) {
        _emitFirstPage(first);
      }

      // The first page tells us how many pages exist, so the rest can be
      // requested together instead of one round trip per page.
      final pages = <FavoritesPage>[first];
      final lastNumber = firstNumber + first.totalPages - 1;
      if (first.hasNextPage) {
        for (var start = firstNumber + 1;
            start <= lastNumber;
            start += _parallelPages) {
          final end = math.min(start + _parallelPages - 1, lastNumber);
          final batch = await Future.wait<FavoritesPage>(<Future<FavoritesPage>>[
            for (var number = start; number <= end; number++)
              _getPage(pageNumber: number, pageSize: _paging.pageSize),
          ]);
          if (isClosed) return;
          pages.addAll(batch);
        }
      }

      // A toggle started or finished meanwhile: this snapshot may predate it.
      if (version != _version) {
        _scheduleRefresh();
        return;
      }

      var items = _deduplicate(<FavoriteMenuItem>[
        for (final page in pages) ...page.items,
      ]);
      final ids = <String>{
        for (final item in items) item.menuItemId.toLowerCase(),
      };
      // Toggles still in flight started before this fetch began; keep them.
      for (final entry in _jobs.entries) {
        if (entry.value.desired) {
          ids.add(entry.key);
        } else {
          ids.remove(entry.key);
          items = items
              .where((item) => item.menuItemId.toLowerCase() != entry.key)
              .toList(growable: false);
        }
      }
      _pageEpoch++;
      emit(
        FavoritesState(
          status: ids.isEmpty ? FavoritesStatus.empty : FavoritesStatus.populated,
          items: List<FavoriteMenuItem>.unmodifiable(items),
          favoriteIds: Set<String>.unmodifiable(ids),
          pendingIds: Set<String>.unmodifiable(_jobs.keys),
          pageNumber: pages.last.pageNumber,
          totalPages: first.totalPages,
          totalCount: ids.length,
          indexComplete: true,
          cacheTimestamp: DateTime.now().toUtc(),
        ),
      );
      _schedulePersist();
    } catch (error) {
      if (isClosed) return;
      _refreshFailure(
        _failureOf(error),
        version,
        reportFailure: reportFailure,
      );
    }
  }

  void _refreshFailure(
    Failure failure,
    int version, {
    required bool reportFailure,
  }) {
    if (version != _version) return;
    // A background failure never replaces valid (even cached) content.
    if (reportFailure ||
        (state.items.isEmpty &&
            state.status == FavoritesStatus.loading &&
            state.cacheTimestamp == null)) {
      emit(state.copyWith(status: FavoritesStatus.error, failure: failure));
    }
  }

  void _scheduleRefresh() {
    if (isClosed) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_refreshDelay, () {
      if (isClosed) return;
      if (_jobs.isNotEmpty) {
        _scheduleRefresh(); // wait until the toggles settle
        return;
      }
      unawaited(_refresh(showLoading: false));
    });
  }

  // ---------------------------------------------------------------------
  // Toggle
  // ---------------------------------------------------------------------

  Future<FavoriteMutationResult> toggle(String menuItemId) {
    final id = menuItemId.trim();
    if (!isFavoriteMenuItemId(id)) {
      return Future<FavoriteMutationResult>.value(FavoriteMutationResult.failed);
    }
    if (isClosed) {
      return Future<FavoriteMutationResult>.value(FavoriteMutationResult.busy);
    }
    // A tap during the first moments after launch waits for the account id.
    if (_userId == null) return _toggleAfterStart(id);
    final key = id.toLowerCase();

    final running = _jobs[key];
    if (running != null) {
      // Another tap during the request: flip the target, keep one request.
      running.desired = !running.desired;
      _applyOptimistic(key, running);
      return Future<FavoriteMutationResult>.value(FavoriteMutationResult.busy);
    }

    final wasFavorite = state.favoriteIds.contains(key);
    final known = state.indexComplete || wasFavorite;
    final job = _ToggleJob(
      id: id,
      wasFavorite: wasFavorite,
      desired: !wasFavorite,
      confirmed: known ? wasFavorite : null,
    );
    _jobs[key] = job;
    _version++;
    _applyOptimistic(key, job);
    unawaited(_runToggle(key, job));
    return job.done.future;
  }

  Future<FavoriteMutationResult> _toggleAfterStart(String id) async {
    if (!await _ensureStarted()) return FavoriteMutationResult.busy;
    return toggle(id);
  }

  Future<void> _runToggle(String key, _ToggleJob job) async {
    Failure? failure;
    try {
      // Before the full index exists, ask the server about this one item
      // instead of loading every page first.
      var confirmed = job.confirmed ?? await _repository.isFavorite(job.id);
      job.confirmed = confirmed;
      if (confirmed != job.wasFavorite) job.membershipWasWrong = true;

      while (!isClosed && job.desired != confirmed) {
        if (job.desired) {
          final item = await _add(job.id);
          if (item.menuItemId.toLowerCase() != key) {
            throw const FailureException(
              Failure(
                FailureCode.validation,
                debugMessage: 'Favorite response did not match requested item',
              ),
            );
          }
          job.item = item;
          confirmed = true;
        } else {
          final removedId = await _remove(job.id);
          if (removedId.toLowerCase() != key) {
            throw const FailureException(
              Failure(
                FailureCode.validation,
                debugMessage: 'Favorite removal response did not match '
                    'requested item',
              ),
            );
          }
          confirmed = false;
        }
        job.confirmed = confirmed;
      }
    } catch (error) {
      failure = _failureOf(error);
    }

    if (identical(_jobs[key], job)) _jobs.remove(key);
    if (isClosed) {
      job.done.complete(FavoriteMutationResult.busy);
      return;
    }
    _version++;

    if (failure != null) {
      _rollback(key, job);
    } else {
      _settle(key, job);
    }
    _schedulePersist();
    // A failed request may or may not have reached the server, and a wrong
    // guess about an unknown item skews the count: re-read the truth once.
    if (failure != null || job.membershipWasWrong) _scheduleRefresh();
    job.done.complete(
      failure == null
          ? FavoriteMutationResult.success
          : FavoriteMutationResult.failed,
    );
  }

  /// Shows [job]'s desired state immediately.
  void _applyOptimistic(String key, _ToggleJob job) {
    final ids = Set<String>.of(state.favoriteIds);
    var items = state.items;
    var count = state.totalCount;
    final present = ids.contains(key);

    if (job.desired && !present) {
      ids.add(key);
      count++;
      final remembered = job.item;
      if (remembered != null) {
        items = _inserted(items, remembered, job.index);
      }
    } else if (!job.desired && present) {
      ids.remove(key);
      count = math.max(0, count - 1);
      final index = items.indexWhere(
        (item) => item.menuItemId.toLowerCase() == key,
      );
      if (index >= 0) {
        job.item = items[index];
        job.index = index;
        items = <FavoriteMenuItem>[...items]..removeAt(index);
      }
    }
    _emitMembership(items, ids, count);
  }

  /// Puts membership back to what the server last confirmed.
  void _rollback(String key, _ToggleJob job) {
    final restoreFavorite = job.confirmed ?? job.wasFavorite;
    final ids = Set<String>.of(state.favoriteIds);
    var items = state.items;
    var count = state.totalCount;
    final present = ids.contains(key);

    if (restoreFavorite && !present) {
      ids.add(key);
      count++;
      final remembered = job.item;
      if (remembered != null) items = _inserted(items, remembered, job.index);
    } else if (!restoreFavorite && present) {
      ids.remove(key);
      count = math.max(0, count - 1);
      items = items
          .where((item) => item.menuItemId.toLowerCase() != key)
          .toList(growable: false);
    }
    _emitMembership(items, ids, count);
  }

  /// A confirmed add brings the item's data; show it in the list now.
  void _settle(String key, _ToggleJob job) {
    final item = job.item;
    var items = state.items;
    if (job.confirmed == true &&
        item != null &&
        !items.any((value) => value.menuItemId.toLowerCase() == key)) {
      items = _inserted(items, item, 0);
    }
    _emitMembership(items, state.favoriteIds, state.totalCount);
  }

  void _emitMembership(
    List<FavoriteMenuItem> items,
    Set<String> ids,
    int count,
  ) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: ids.isEmpty && items.isEmpty
            ? FavoritesStatus.empty
            : FavoritesStatus.populated,
        items: List<FavoriteMenuItem>.unmodifiable(items),
        favoriteIds: Set<String>.unmodifiable(ids),
        pendingIds: Set<String>.unmodifiable(_jobs.keys),
        totalCount: count,
      ),
    );
  }

  List<FavoriteMenuItem> _inserted(
    List<FavoriteMenuItem> items,
    FavoriteMenuItem item,
    int index,
  ) {
    final key = item.menuItemId.toLowerCase();
    if (items.any((value) => value.menuItemId.toLowerCase() == key)) {
      return items;
    }
    return <FavoriteMenuItem>[...items]
      ..insert(math.min(math.max(index, 0), items.length), item);
  }

  // ---------------------------------------------------------------------
  // Pagination (only needed while the list is a restored first page)
  // ---------------------------------------------------------------------

  Future<void> loadNextPage() => _loadNextPage();
  Future<void> retryNextPage() => _loadNextPage(retry: true);

  Future<void> _loadNextPage({bool retry = false}) async {
    final current = state;
    if (isClosed ||
        _userId == null ||
        current.loadingMore ||
        !current.hasNextPage ||
        current.pageNumber == null ||
        (!retry && current.nextPageFailure != null)) {
      return;
    }
    final epoch = ++_pageEpoch;
    emit(current.copyWith(loadingMore: true, clearNextPageFailure: true));
    try {
      final page = await _getPage(
        pageNumber: current.pageNumber! + 1,
        pageSize: _paging.pageSize,
      );
      // A refresh replaced the list meanwhile and already reset the flags.
      if (isClosed || epoch != _pageEpoch) return;
      final fresh = page.items.where((item) {
        final job = _jobs[item.menuItemId.toLowerCase()];
        return job == null || job.desired;
      });
      final items = _deduplicate(<FavoriteMenuItem>[...state.items, ...fresh]);
      emit(
        state.copyWith(
          status: FavoritesStatus.populated,
          items: List<FavoriteMenuItem>.unmodifiable(items),
          favoriteIds: Set<String>.unmodifiable(<String>{
            ...state.favoriteIds,
            for (final item in fresh) item.menuItemId.toLowerCase(),
          }),
          pageNumber: page.pageNumber,
          totalPages: page.totalPages,
          hasNextPage: page.hasNextPage,
          loadingMore: false,
        ),
      );
      _schedulePersist();
    } catch (error) {
      if (isClosed || epoch != _pageEpoch) return;
      emit(
        state.copyWith(loadingMore: false, nextPageFailure: _failureOf(error)),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------

  void _restore(FavoritesCacheSnapshot cache) {
    emit(
      FavoritesState(
        status: cache.totalCount == 0
            ? FavoritesStatus.empty
            : FavoritesStatus.populated,
        items: cache.items,
        favoriteIds: cache.favoriteIds,
        pageNumber: cache.pageNumber,
        totalPages: cache.totalPages,
        totalCount: cache.totalCount,
        hasNextPage: cache.hasNextPage,
        indexComplete: cache.indexComplete,
        cacheTimestamp: cache.savedAt,
      ),
    );
  }

  void _emitFirstPage(FavoritesPage page) {
    _pageEpoch++;
    emit(
      FavoritesState(
        status: page.items.isEmpty
            ? FavoritesStatus.empty
            : FavoritesStatus.populated,
        items: page.items,
        favoriteIds: <String>{
          for (final item in page.items) item.menuItemId.toLowerCase(),
        },
        pageNumber: page.pageNumber,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        hasNextPage: page.hasNextPage,
        // Unknown ids stay unknown until every page is collected.
        indexComplete: false,
      ),
    );
  }

  /// Writes are debounced and never awaited: a heart tap must not wait on
  /// disk, and a storage error must never affect a confirmed server change.
  void _schedulePersist() {
    _persistDirty = true;
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDelay, _flushPersist);
  }

  void _flushPersist() {
    _persistTimer?.cancel();
    final userId = _userId;
    final current = state;
    if (!_persistDirty ||
        userId == null ||
        !current.indexComplete ||
        current.favoriteIds.length > _maxCachedIds) {
      return;
    }
    _persistDirty = false;
    final items = current.items.take(_paging.pageSize).toList(growable: false);
    final snapshot = FavoritesCacheSnapshot(
      favoriteIds: current.favoriteIds,
      items: items,
      totalCount: current.favoriteIds.length,
      pageNumber: _paging.firstPage,
      totalPages: current.totalPages,
      hasNextPage: current.favoriteIds.length > items.length,
      hasPreviousPage: false,
      indexComplete: true,
      savedAt: DateTime.now().toUtc(),
    );
    unawaited(
      _repository.writeCache(userId, snapshot).catchError((Object _) {}),
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  bool _isFresh(DateTime timestamp) {
    final age = DateTime.now().toUtc().difference(timestamp.toUtc());
    return age >= Duration.zero && age < freshnessWindow;
  }

  List<FavoriteMenuItem> _deduplicate(Iterable<FavoriteMenuItem> items) =>
      <String, FavoriteMenuItem>{
        for (final item in items) item.menuItemId.toLowerCase(): item,
      }.values.toList(growable: false);

  Future<String?> _readUserId() async {
    try {
      final userId = (await _getAuthenticatedUserId())?.trim();
      return userId == null || userId.isEmpty ? null : userId;
    } catch (_) {
      return null;
    }
  }

  Failure _failureOf(Object error) => error is FailureException
      ? error.failure
      : Failure(FailureCode.unknown, debugMessage: error.toString());

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _flushPersist(); // keep the last confirmed state for the next launch
    _persistTimer?.cancel();
    return super.close();
  }
}

class _ToggleJob {
  _ToggleJob({
    required this.id,
    required this.wasFavorite,
    required this.desired,
    required this.confirmed,
  });

  final String id;

  /// Membership when the job started (what a rollback restores to if the
  /// server never confirmed anything).
  final bool wasFavorite;

  /// Latest requested membership; repeated taps flip it.
  bool desired;

  /// Membership the server last confirmed; null while still unknown.
  bool? confirmed;

  /// Item data, remembered so a failed removal can put it back in place.
  FavoriteMenuItem? item;
  int index = 0;

  /// The guess made before the index existed turned out wrong.
  bool membershipWasWrong = false;

  final Completer<FavoriteMutationResult> done =
      Completer<FavoriteMutationResult>();
}
