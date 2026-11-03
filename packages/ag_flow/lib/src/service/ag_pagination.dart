/// How a backend pages its collections — the paging dialect, named once
/// per Service.
///
/// It only *describes* paging: [query] says which query parameters request
/// a page, and [isLastPage] says when to stop. It never sends a request —
/// the Service's own `list` body does that. Opt in by overriding
/// `AgBaseService.pagination`; delete that one line to turn paging off.
///
/// Pages are numbered from 1. For a backend that pages some other way,
/// extend this class and implement [query].
abstract class AgPagination {
  const AgPagination({this.pageSize = 20});

  /// How many items one page holds.
  final int pageSize;

  /// The query parameters that request [page] (1-based).
  Map<String, dynamic> query(int page);

  /// Whether [items] — one page, as returned by the backend — is the last
  /// one. A short page means the backend ran out.
  bool isLastPage(List<Object?> items) => items.length < pageSize;
}

/// `?page=2&limit=20` — rename either parameter to match the backend, e.g.
/// `AgPageNumberPagination(pageParam: '_page', sizeParam: '_limit')`.
class AgPageNumberPagination extends AgPagination {
  const AgPageNumberPagination({
    super.pageSize,
    this.pageParam = 'page',
    this.sizeParam = 'limit',
  });

  /// The query parameter carrying the page number.
  final String pageParam;

  /// The query parameter carrying [pageSize].
  final String sizeParam;

  @override
  Map<String, dynamic> query(int page) => {
    pageParam: '$page',
    sizeParam: '$pageSize',
  };
}

/// `?offset=20&limit=20` — page 2 starts after the first [pageSize] items.
class AgLimitOffsetPagination extends AgPagination {
  const AgLimitOffsetPagination({
    super.pageSize,
    this.offsetParam = 'offset',
    this.limitParam = 'limit',
  });

  /// The query parameter carrying the number of items to skip.
  final String offsetParam;

  /// The query parameter carrying [pageSize].
  final String limitParam;

  @override
  Map<String, dynamic> query(int page) => {
    offsetParam: '${(page - 1) * pageSize}',
    limitParam: '$pageSize',
  };
}
