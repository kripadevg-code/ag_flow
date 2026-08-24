import 'package:ag_flow/src/controller/ag_base_controller.dart';
import 'package:ag_flow/src/controller/ag_pagination_state.dart';
import 'package:ag_flow/src/state/ag_notifier.dart';
import 'package:flutter/foundation.dart';

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
  /// Notifies pagination-state rebuilds — kept as a separate [AgNotifier]
  /// from the controller's own page-state notifications (see
  /// [AgBaseController]'s class doc for why).
  final AgNotifier _paginationNotifier = AgNotifier();

  /// The [Listenable] pagination-state rebuilds (`AgListBuilder`) should
  /// listen to.
  Listenable get paginationListenable => _paginationNotifier;

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
    // Mirrors AgBaseController.emit's own guard: an in-flight fetchPage
    // may well outlive the route that started it.
    if (isDisposed) return;
    _pagination = next;
    _paginationNotifier.notify();
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

  /// Escape hatch for feature-specific pagination-state transitions — the
  /// [AgPaginationMixin] equivalent of [AgBaseController.emit]. Use this
  /// to reflect a mutation (an add/update/delete against the Repo) in the
  /// currently-displayed list directly, when a full [refresh] wouldn't
  /// show it (e.g. a demo/mock backend that doesn't actually persist
  /// writes, or simply to avoid the round-trip for an optimistic update).
  @protected
  void updateItems(
    List<ItemType> Function(List<ItemType> items) transform,
  ) {
    _setPagination(pagination.copyWith(items: transform(pagination.items)));
  }

  @override
  Future<void> refresh() async {
    _setPagination(AgPaginationState<ItemType, PageKeyType>());
    await super.refresh();
  }

  @override
  void dispose() {
    _paginationNotifier.dispose();
    super.dispose();
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
