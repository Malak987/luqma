/// Deployment-configurable client paging defaults, not inferred API limits.
class FavoritePaging {
  const FavoritePaging({this.firstPage = 1, this.pageSize = 20})
      : assert(firstPage >= 0),
        assert(pageSize > 0);

  final int firstPage;
  final int pageSize;
}
