import '../../../../core/error/failures.dart';
import '../../domain/entities/catalog_page.dart';
import '../../domain/entities/menu_category.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/queries/menu_item_query.dart';
import '../../domain/repositories/menu_memory_cache.dart';
import '../../domain/repositories/store_menu_repository.dart';

class _Entry<T> {
  const _Entry(this.value, this.at);
  final T value;
  final DateTime at;
}

/// One application-wide cache for verified public menu responses. Queries keep
/// every backend-affecting filter and pagination value. Failed refreshes never
/// replace a snapshot. Entries are bounded and expire after three minutes.
class CachedStoreMenuRepository
    implements StoreMenuRepository, MenuMemoryCache {
  CachedStoreMenuRepository(this._remote,
      {this.ttl = const Duration(minutes: 3), DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;
  final StoreMenuRepository _remote;
  final Duration ttl;
  final DateTime Function() _clock;
  final _categories = <String, _Entry<List<MenuCategory>>>{};
  final _items = <MenuItemQuery, _Entry<CatalogPage<MenuItem>>>{};
  final _categoryRequests = <String, Future<List<MenuCategory>>>{};
  final _itemRequests = <MenuItemQuery, Future<CatalogPage<MenuItem>>>{};

  MenuItemQuery _key(MenuItemQuery q) => MenuItemQuery(
      storeId: q.storeId.toLowerCase(),
      filters: q.filters.withCategory(q.filters.menuCategoryId?.toLowerCase()),
      pageNumber: q.pageNumber,
      pageSize: q.pageSize);
  MenuCacheEntry<T>? _read<T>(_Entry<T>? entry) {
    if (entry == null) return null;
    final age = _clock().difference(entry.at);
    return MenuCacheEntry(entry.value, !age.isNegative && age < ttl);
  }

  void _put<K, V>(Map<K, _Entry<V>> map, K key, V value) {
    map.remove(key);
    map[key] = _Entry(value, _clock());
    if (map.length > 100) map.remove(map.keys.first);
  }

  @override
  MenuCacheEntry<List<MenuCategory>>? categoriesSnapshot(String storeId) =>
      _read(_categories[storeId.toLowerCase()]);
  @override
  MenuCacheEntry<CatalogPage<MenuItem>>? itemsSnapshot(MenuItemQuery query) =>
      _read(_items[_key(query)]);

  @override
  Future<List<MenuCategory>> getActiveCategories(String storeId) {
    final key = storeId.toLowerCase();
    final cached = categoriesSnapshot(key);
    if (cached?.fresh == true) return Future.value(cached!.value);
    final pending = _categoryRequests[key];
    if (pending != null) return pending;
    final future = _remote.getActiveCategories(storeId).then((value) {
      if (value.any((x) => x.storeId.toLowerCase() != key))
        throw const FailureException(Failure(FailureCode.unknown));
      final active = <String, MenuCategory>{
        for (final category in value)
          if (category.isActive) category.id.toLowerCase(): category,
      }.values.toList()
        ..sort((a, b) {
          final order = a.displayOrder.compareTo(b.displayOrder);
          return order == 0 ? a.id.compareTo(b.id) : order;
        });
      final immutable = List<MenuCategory>.unmodifiable(active);
      _put(_categories, key, immutable);
      return immutable;
    });
    _categoryRequests[key] = future;
    future.then<void>((_) => _categoryRequests.remove(key),
        onError: (Object _, StackTrace __) {
      _categoryRequests.remove(key);
    });
    return future;
  }

  @override
  Future<CatalogPage<MenuItem>> getItems(MenuItemQuery query) {
    // Global product lookup is used by favorites; preserve its existing
    // server synchronization rather than caching that separate flow.
    if (query.storeId.isEmpty) return _remote.getItems(query);
    final key = _key(query);
    final cached = itemsSnapshot(key);
    if (cached?.fresh == true) return Future.value(cached!.value);
    final pending = _itemRequests[key];
    if (pending != null) return pending;
    final future = _remote.getItems(query).then((page) {
      final id = query.filters.menuCategoryId?.toLowerCase();
      if (page.pageNumber != query.pageNumber ||
          page.items.any((item) =>
              !item.isActive ||
              (id != null && item.menuCategoryId.toLowerCase() != id))) {
        throw const FailureException(Failure(FailureCode.unknown));
      }
      _put(_items, key, page);
      return page;
    });
    _itemRequests[key] = future;
    future.then<void>((_) => _itemRequests.remove(key),
        onError: (Object _, StackTrace __) {
      _itemRequests.remove(key);
    });
    return future;
  }
}
