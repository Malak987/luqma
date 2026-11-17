import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/favorite_menu_item.dart';
import '../../domain/entities/favorites_page.dart';
import '../../domain/queries/favorite_paging.dart';
import '../../domain/usecases/add_to_favorites_use_case.dart';
import '../../domain/usecases/get_favorites_count_use_case.dart';
import '../../domain/usecases/get_my_favorites_use_case.dart';
import '../../domain/usecases/is_favorite_use_case.dart';
import '../../domain/usecases/remove_from_favorites_use_case.dart';
import 'favorites_state.dart';

enum FavoriteMutationResult { success, busy, failed, synchronizationFailed }

/// Authenticated-shell Favorites coordinator.
///
/// It owns the single membership cache consumed by cards, product details and
/// the Favorites page. Every add/remove is serialized, duplicate toggles share
/// one future, and the returned mutation is followed by an authoritative list
/// and count refresh rather than unsafe optimistic list edits.
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({
    required AddToFavoritesUseCase addToFavoritesUseCase,
    required RemoveFromFavoritesUseCase removeFromFavoritesUseCase,
    required GetMyFavoritesUseCase getMyFavoritesUseCase,
    required IsFavoriteUseCase isFavoriteUseCase,
    required GetFavoritesCountUseCase getFavoritesCountUseCase,
    required FavoritePaging paging,
  })  : _addToFavoritesUseCase = addToFavoritesUseCase,
        _removeFromFavoritesUseCase = removeFromFavoritesUseCase,
        _getMyFavoritesUseCase = getMyFavoritesUseCase,
        _isFavoriteUseCase = isFavoriteUseCase,
        _getFavoritesCountUseCase = getFavoritesCountUseCase,
        _paging = paging,
        super(FavoritesState());

  final AddToFavoritesUseCase _addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase _removeFromFavoritesUseCase;
  final GetMyFavoritesUseCase _getMyFavoritesUseCase;
  final IsFavoriteUseCase _isFavoriteUseCase;
  final GetFavoritesCountUseCase _getFavoritesCountUseCase;
  final FavoritePaging _paging;

  final Map<String, Future<bool>> _statusRequests = <String, Future<bool>>{};
  final Map<String, Future<FavoriteMutationResult>> _toggleRequests =
      <String, Future<FavoriteMutationResult>>{};
  bool _started = false;
  bool _isRefreshing = false;
  bool _isMutating = false;
  int _snapshotVersion = 0;
  int _membershipVersion = 0;
  _PendingFavoritesSnapshot? _pendingRefreshSnapshot;

  Future<void> load() {
    if (isClosed || _started) return Future<void>.value();
    _started = true;
    return refresh();
  }

  /// Refreshes the first server page and the count together. A fresh shell is
  /// created per authenticated session, so no prior account snapshot survives.
  Future<void> refresh() async {
    if (isClosed || _isRefreshing || _isMutating) return;
    _isRefreshing = true;
    try {
      await _fetchAuthoritative(
        pageNumber: _paging.firstPage,
        showLoading: true,
      );
    } finally {
      _isRefreshing = false;
    }
  }

  /// Obtains membership for a visible menu item only once. The request is
  /// de-duplicated while in flight, and a completed mutation invalidates any
  /// older IsFavorite response before it can overwrite the result.
  Future<void> ensureFavoriteStatus(String menuItemId) async {
    await _ensureFavoriteStatus(menuItemId);
  }

  Future<FavoriteMutationResult> toggle(String menuItemId) {
    final id = menuItemId.trim();
    final key = id.toLowerCase();
    final pending = _toggleRequests[key];
    if (pending != null) return pending;

    late final Future<FavoriteMutationResult> request;
    request = _toggle(id).whenComplete(() {
      if (identical(_toggleRequests[key], request)) {
        _toggleRequests.remove(key);
      }
    });
    _toggleRequests[key] = request;
    return request;
  }

  Future<void> loadNextPage() => _loadNextPage();
  Future<void> retryNextPage() => _loadNextPage(retry: true);

  Future<bool> _ensureFavoriteStatus(String menuItemId) {
    final id = menuItemId.trim();
    final key = id.toLowerCase();
    if (id.isEmpty || state.knowsFavorite(key)) return Future<bool>.value(true);
    final pending = _statusRequests[key];
    if (pending != null) return pending;

    final request = _resolveFavoriteStatus(id, key);
    _statusRequests[key] = request;
    request.whenComplete(() {
      if (identical(_statusRequests[key], request)) {
        _statusRequests.remove(key);
      }
    });
    return request;
  }

  Future<bool> _resolveFavoriteStatus(String id, String key) async {
    final membershipVersion = _membershipVersion;
    final checking = <String>{...state.checkingMenuItemIds, key};
    if (!isClosed) {
      emit(state.copyWith(checkingMenuItemIds: checking, clearFailure: true));
    }
    try {
      final isFavorite = await _isFavoriteUseCase(id);
      if (isClosed || membershipVersion != _membershipVersion) return false;
      final known = <String, bool>{...state.favoriteByMenuItemId, key: isFavorite};
      checking.remove(key);
      emit(
        state.copyWith(
          favoriteByMenuItemId: known,
          checkingMenuItemIds: checking,
          clearFailure: true,
        ),
      );
      return true;
    } on FailureException catch (error) {
      _emitMembershipFailure(key, error.failure, membershipVersion, checking);
      return false;
    } catch (error) {
      _emitMembershipFailure(
        key,
        Failure(FailureCode.unknown, debugMessage: error.toString()),
        membershipVersion,
        checking,
      );
      return false;
    }
  }

  void _emitMembershipFailure(
    String key,
    Failure failure,
    int membershipVersion,
    Set<String> checking,
  ) {
    if (isClosed || membershipVersion != _membershipVersion) return;
    checking.remove(key);
    // A per-heart status failure must not erase an already usable Favorites
    // page. Its failure is retained for retry through the next interaction.
    emit(
      state.copyWith(
        checkingMenuItemIds: checking,
        failure: failure,
      ),
    );
  }

  Future<FavoriteMutationResult> _toggle(String menuItemId) async {
    if (isClosed || _isMutating) return FavoriteMutationResult.busy;
    if (!await _ensureFavoriteStatus(menuItemId) || isClosed) {
      return FavoriteMutationResult.failed;
    }
    if (_isMutating) return FavoriteMutationResult.busy;

    final key = menuItemId.toLowerCase();
    final wasFavorite = state.isFavorite(key);
    _isMutating = true;
    _membershipVersion++;
    emit(state.copyWith(clearFailure: true, isMutating: true));
    try {
      if (wasFavorite) {
        await _removeFromFavoritesUseCase(menuItemId);
      } else {
        final added = await _addToFavoritesUseCase(menuItemId);
        if (added.menuItemId.toLowerCase() != key) {
          throw const FailureException(
            Failure(
              FailureCode.validation,
              debugMessage: 'Favorite response did not match requested item',
            ),
          );
        }
      }
    } on FailureException catch (error) {
      _emitMutationFailure(error.failure);
      return FavoriteMutationResult.failed;
    } catch (error) {
      _emitMutationFailure(
        Failure(FailureCode.unknown, debugMessage: error.toString()),
      );
      return FavoriteMutationResult.failed;
    }

    // This membership update follows a successful server mutation, so it is
    // not an optimistic removal. The list and count below remain authoritative
    // for all page/badge data.
    final known = <String, bool>{...state.favoriteByMenuItemId, key: !wasFavorite};
    if (!isClosed) {
      emit(state.copyWith(favoriteByMenuItemId: known, isMutating: true));
    }

    _snapshotVersion++;
    _pendingRefreshSnapshot = null;
    final synchronized = await _fetchAuthoritative(
      pageNumber: _paging.firstPage,
      showLoading: false,
      allowDuringMutation: true,
    );
    if (isClosed) return FavoriteMutationResult.busy;
    _isMutating = false;
    emit(state.copyWith(isMutating: false));
    return synchronized
        ? FavoriteMutationResult.success
        : FavoriteMutationResult.synchronizationFailed;
  }

  Future<bool> _fetchAuthoritative({
    required int pageNumber,
    required bool showLoading,
    bool allowDuringMutation = false,
  }) async {
    if (isClosed) return false;
    final version = _snapshotVersion;
    if (showLoading) {
      emit(
        state.copyWith(
          status: FavoritesStatus.loading,
          loadingMore: false,
          clearFailure: true,
          clearNextPageFailure: true,
          isMutating: _isMutating,
        ),
      );
    }
    try {
      final values = await Future.wait<Object>(<Future<Object>>[
        _getMyFavoritesUseCase(
          pageNumber: pageNumber,
          pageSize: _paging.pageSize,
        ),
        _getFavoritesCountUseCase(),
      ]);
      if (isClosed || version != _snapshotVersion) return false;
      final page = values[0] as FavoritesPage;
      final count = values[1] as int;
      if (_isMutating && !allowDuringMutation) {
        _pendingRefreshSnapshot = _PendingFavoritesSnapshot(page, count);
      } else {
        _emitAuthoritativePage(page, count);
      }
      return true;
    } on FailureException catch (error) {
      _emitRefreshFailure(error.failure, version, allowDuringMutation);
      return false;
    } catch (error) {
      _emitRefreshFailure(
        Failure(FailureCode.unknown, debugMessage: error.toString()),
        version,
        allowDuringMutation,
      );
      return false;
    }
  }

  void _emitAuthoritativePage(FavoritesPage page, int count) {
    if (isClosed) return;
    final known = <String, bool>{...state.favoriteByMenuItemId};
    for (final item in page.items) {
      known[item.menuItemId.toLowerCase()] = true;
    }
    emit(
      FavoritesState(
        status:
            page.items.isEmpty ? FavoritesStatus.empty : FavoritesStatus.populated,
        items: page.items,
        favoriteByMenuItemId: known,
        checkingMenuItemIds: state.checkingMenuItemIds,
        pageNumber: page.pageNumber,
        totalPages: page.totalPages,
        totalCount: count,
        hasPreviousPage: page.hasPreviousPage,
        hasNextPage: page.hasNextPage,
        isMutating: _isMutating,
      ),
    );
  }

  void _emitRefreshFailure(
    Failure failure,
    int version,
    bool allowDuringMutation,
  ) {
    if (isClosed ||
        version != _snapshotVersion ||
        (_isMutating && !allowDuringMutation)) {
      return;
    }
    emit(
      state.copyWith(
        status: FavoritesStatus.error,
        loadingMore: false,
        failure: failure,
        isMutating: _isMutating,
      ),
    );
  }

  Future<void> _loadNextPage({bool retry = false}) async {
    if (isClosed || _isMutating) return;
    final current = state;
    if (current.status != FavoritesStatus.populated ||
        !current.hasNextPage ||
        current.pageNumber == null ||
        current.loadingMore ||
        (!retry && current.nextPageFailure != null)) {
      return;
    }
    final version = _snapshotVersion;
    emit(
      current.copyWith(
        loadingMore: true,
        clearNextPageFailure: true,
      ),
    );
    try {
      final page = await _getMyFavoritesUseCase(
        pageNumber: current.pageNumber! + 1,
        pageSize: _paging.pageSize,
      );
      if (isClosed || version != _snapshotVersion || _isMutating) return;
      final items = _deduplicate(<FavoriteMenuItem>[...current.items, ...page.items]);
      final known = <String, bool>{...state.favoriteByMenuItemId};
      for (final item in page.items) {
        known[item.menuItemId.toLowerCase()] = true;
      }
      emit(
        FavoritesState(
          status: items.isEmpty ? FavoritesStatus.empty : FavoritesStatus.populated,
          items: items,
          favoriteByMenuItemId: known,
          checkingMenuItemIds: state.checkingMenuItemIds,
          pageNumber: page.pageNumber,
          totalPages: page.totalPages,
          totalCount: state.totalCount,
          hasPreviousPage: page.hasPreviousPage,
          hasNextPage: page.hasNextPage,
        ),
      );
    } on FailureException catch (error) {
      _emitNextPageFailure(error.failure, version);
    } catch (error) {
      _emitNextPageFailure(
        Failure(FailureCode.unknown, debugMessage: error.toString()),
        version,
      );
    }
  }

  void _emitNextPageFailure(Failure failure, int version) {
    if (isClosed || version != _snapshotVersion || _isMutating) return;
    emit(
      state.copyWith(
        loadingMore: false,
        nextPageFailure: failure,
      ),
    );
  }

  void _emitMutationFailure(Failure failure) {
    _isMutating = false;
    final pending = _pendingRefreshSnapshot;
    _pendingRefreshSnapshot = null;
    if (isClosed) return;
    if (pending != null) {
      _emitAuthoritativePage(pending.page, pending.count);
    }
    final recoveredStatus = state.isLoading
        ? state.items.isEmpty
            ? FavoritesStatus.error
            : FavoritesStatus.populated
        : null;
    emit(
      state.copyWith(
        status: recoveredStatus,
        failure: failure,
        isMutating: false,
      ),
    );
  }

  List<FavoriteMenuItem> _deduplicate(List<FavoriteMenuItem> items) =>
      <String, FavoriteMenuItem>{
        for (final item in items) item.menuItemId.toLowerCase(): item,
      }.values.toList(growable: false);
}

class _PendingFavoritesSnapshot {
  const _PendingFavoritesSnapshot(this.page, this.count);

  final FavoritesPage page;
  final int count;
}
