import 'package:ag_flow/src/controller/ag_base_controller.dart';
import 'package:ag_flow/src/page/ag_page_state.dart';
import 'package:flutter/foundation.dart';

/// Opt-in load-more for a controller whose data is a [List].
///
/// Add `with AgLoadMore<Post>` and implement [list] (pages start at
/// 1) instead of `fetch`. Remove the mixin and write `fetch` again to turn
/// paging off — nothing else in the controller or page changes, because
/// `AgListView` adapts to whichever it finds.
///
/// Appended pages go into the controller's own `state`, so the page shows
/// them like any other success. Load-more progress ([isLoadingMore],
/// [hasMore], [loadMoreError]) is kept apart from that state: a failed
/// page never replaces a list that is already on screen.
mixin AgLoadMore<T> on AgBaseController<List<T>> {
  int _nextPage = 2;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  Object? _loadMoreError;

  /// Fetches one page — call the Repo, never a Service directly.
  @protected
  Future<List<T>> list({int page = 1});

  /// Whether [items] — one page — is the last one. Defaults to "the page
  /// came back empty", which works with any backend at the cost of one
  /// extra request; override it to stop on a short page, e.g.
  /// `items.length < 20`.
  @protected
  bool isLastPage(List<T> items) => items.isEmpty;

  /// Whether another page may exist.
  bool get hasMore => _hasMore;

  /// Whether a [loadMore] is in flight.
  bool get isLoadingMore => _isLoadingMore;

  /// Why the last [loadMore] failed, until the next attempt.
  Object? get loadMoreError => _loadMoreError;

  @override
  Future<List<T>> fetch() async {
    // A (re)load starts paging over; an in-flight load-more is abandoned
    // by the new request token rather than awaited.
    _nextPage = 2;
    _hasMore = true;
    _isLoadingMore = false;
    _loadMoreError = null;
    final token = currentRequestToken;
    final items = await list();
    if (isCurrentRequest(token)) _hasMore = !isLastPage(items);
    return items;
  }

  /// Loads the next page and appends it, if one may exist and none is
  /// already loading. Safe to call on every scroll frame.
  Future<void> loadMore() async {
    final current = state;
    if (current is! AgPageSuccess<List<T>> || !_hasMore || _isLoadingMore) {
      return;
    }
    _isLoadingMore = true;
    _loadMoreError = null;
    _notify();
    // Captured, not started: a load-more continues the current load rather
    // than replacing it, so a refresh() that starts meanwhile makes this
    // token stale and the page is dropped instead of appended onto the
    // refreshed list.
    final token = currentRequestToken;
    try {
      final items = await list(page: _nextPage);
      if (!isCurrentRequest(token)) return;
      _nextPage++;
      _hasMore = !isLastPage(items);
      _isLoadingMore = false;
      final shown = state.dataOrNull ?? const [];
      emit(AgPageState.success([...shown, ...items]));
      // A developer's list() may throw anything, same as fetch() —
      // captured as loadMoreError, never re-thrown.
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      if (!isCurrentRequest(token)) return;
      _isLoadingMore = false;
      _loadMoreError = error;
      _notify();
    }
  }

  void _notify() {
    if (!isDisposed) notifyListeners();
  }
}
