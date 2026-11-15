/// Deployment-configurable starting values, NOT verified backend limits.
/// Neither a maximum page size nor a short-page heuristic is invented here.
class CatalogPaging {
  const CatalogPaging({this.firstPage = 1, this.pageSize = 20})
      : assert(firstPage >= 0),
        assert(pageSize > 0);

  final int firstPage;
  final int pageSize;
}
