import 'package:ag_flow/src/controller/ag_base_controller.dart';
import 'package:ag_flow/src/controller/ag_pagination_state.dart';

/// Adds pagination/load-more behavior to an [AgBaseController] whose data
/// is a [List].
///
/// Subclasses implement [fetchPage] as a pure "given this page key, fetch
/// one page" function. This mixin is the sole writer of [pagination]
/// state — every write is serialized behind the
/// [AgPaginationState.isLoadingMore] guard, so calling [loadMore]
/// repeatedly (e.g. from a scroll listener) is always safe and never
/// triggers duplicate fetches.
mixin AgPaginationMixin<ItemType, PageKeyType extends Object>
    on AgBaseController<List<ItemType>> {
  /// The `GetBuilder(id:)` every pagination-state rebuild is scoped to —
  /// see [AgBaseController.pageStateUpdateId] for why this is a separate
  /// id from the page-level state.
  static const paginationUpdateId = 'ag_pagination_state';

  /// The page key used for the very first page.
  PageKeyType get initialPageKey;

  /// Fetches a single page of data for [pageKey]. Must call the Repo —
  /// never a Service or `ApiProvider` directly.
  Future<AgListPage<ItemType, PageKeyType>> fetchPage(PageKeyType pageKey);

  AgPaginationState<ItemType, PageKeyType> _pagination =
      AgPaginationState<ItemType, PageKeyType>();

  /// The current pagination/load-more state.
  AgPaginationState<ItemType, PageKeyType> get pagination => _pagination;

  void _setPagination(AgPaginationState<ItemType, PageKeyType> next) {
    _pagination = next;
    update([paginationUpdateId]);
  }

  @override
  Future<List<ItemType>> fetch() async {
    final page = await fetchPage(initialPageKey);
    _setPagination(
      AgPaginationState<ItemType, PageKeyType>(
        items: page.items,
        nextPageKey: page.nextPageKey,
        hasNextPage: page.hasMore,
      ),
    );
    return page.items;
  }

  /// Loads the next page and appends it, if one is available and no
  /// load-more is already in flight.
  Future<void> loadMore() async {
    final current = pagination;
    if (current.isLoadingMore || !current.hasNextPage) return;

    final pageKey = current.nextPageKey;
    if (pageKey == null) {
      _setPagination(current.copyWith(hasNextPage: false));
      return;
    }

    _setPagination(
      current.copyWith(isLoadingMore: true, clearLoadMoreError: true),
    );
    try {
      final page = await fetchPage(pageKey);
      _setPagination(
        pagination.copyWith(
          items: [...pagination.items, ...page.items],
          nextPageKey: page.nextPageKey,
          clearNextPageKey: page.nextPageKey == null,
          hasNextPage: page.hasMore,
          isLoadingMore: false,
        ),
      );
      // A developer's fetchPage() may throw anything, same as fetch() on
      // AgBaseController — captured as loadMoreError, never re-thrown.
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      _setPagination(
        pagination.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }

  /// Retries the most recent failed [loadMore] call.
  Future<void> retryLoadMore() => loadMore();

  @override
  Future<void> refresh() async {
    _setPagination(AgPaginationState<ItemType, PageKeyType>());
    await super.refresh();
  }
}

/// Base class for collection/list modules — combines [AgBaseController]
/// with [AgPaginationMixin].
abstract class AgListController<ItemType, PageKeyType extends Object>
    extends AgBaseController<List<ItemType>>
    with AgPaginationMixin<ItemType, PageKeyType> {
  AgListController({required this.initialPageKey, super.autoLoadOnInit});

  @override
  final PageKeyType initialPageKey;
}
