import 'dart:async';

import 'package:ag_flow/ag_flow.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves pages from [pages]; a page whose entry is a [Completer] stays in
/// flight until the test completes it.
class _Pager extends AgBaseController<List<int>> with AgLoadMore<int> {
  _Pager(this.pages, {this.shortPageSize}) : super(autoLoadOnInit: false);

  final Map<int, Object> pages;
  final int? shortPageSize;
  final List<int> requested = [];

  @override
  Future<List<int>> list({int page = 1}) async {
    requested.add(page);
    final entry = pages[page] ?? const <int>[];
    if (entry is Completer<List<int>>) return entry.future;
    if (entry is Exception) throw entry;
    return entry as List<int>;
  }

  @override
  bool isLastPage(List<int> items) {
    final size = shortPageSize;
    return size == null ? super.isLastPage(items) : items.length < size;
  }
}

void main() {
  test('the first load is page 1, and load-more appends page 2', () async {
    final c = _Pager({
      1: [1, 2],
      2: [3],
    });

    await c.loadInitial();
    expect(c.state.dataOrNull, [1, 2]);
    expect(c.hasMore, isTrue);

    await c.loadMore();
    expect(c.state.dataOrNull, [1, 2, 3]);
    expect(c.requested, [1, 2]);
  });

  test('by default an empty page ends paging', () async {
    final c = _Pager({
      1: [1],
    });

    await c.loadInitial();
    await c.loadMore();
    expect(c.hasMore, isFalse);

    await c.loadMore();
    expect(c.requested, [1, 2], reason: 'no request after the last page');
  });

  test('an isLastPage override stops on a short page', () async {
    final c = _Pager({
      1: [1],
    }, shortPageSize: 2);

    await c.loadInitial();

    expect(c.hasMore, isFalse);
  });

  test('a second loadMore while one is in flight is a no-op', () async {
    final page2 = Completer<List<int>>();
    final c = _Pager({
      1: [1],
      2: page2,
    });
    await c.loadInitial();

    final first = c.loadMore();
    expect(c.isLoadingMore, isTrue);
    await c.loadMore();
    page2.complete([2]);
    await first;

    expect(c.requested, [1, 2]);
    expect(c.state.dataOrNull, [1, 2]);
  });

  test('loadMore does nothing before the first load succeeds', () async {
    final c = _Pager({});

    await c.loadMore();

    expect(c.requested, isEmpty);
  });

  test('a refresh during a load-more drops the stale page', () async {
    final page2 = Completer<List<int>>();
    final c = _Pager({
      1: [1],
      2: page2,
    });
    await c.loadInitial();

    final stale = c.loadMore();
    await c.refresh();
    page2.complete([99]);
    await stale;

    expect(c.state.dataOrNull, [1]);
    expect(c.isLoadingMore, isFalse);
  });

  test('a loadMore during a refresh is a no-op, so no page is skipped', () async {
    final refreshed = Completer<List<int>>();
    final c = _Pager({
      1: [1],
      2: [2],
    });
    await c.loadInitial();

    c.pages[1] = refreshed;
    final refresh = c.refresh();
    await c.loadMore();
    refreshed.complete([1]);
    await refresh;
    await c.loadMore();

    expect(c.requested, [1, 1, 2]);
    expect(c.state.dataOrNull, [1, 2]);
  });

  test('a failed page keeps the list and records the error', () async {
    final c = _Pager({
      1: [1],
      2: Exception('down'),
    });
    await c.loadInitial();

    await c.loadMore();

    expect(c.state, isA<AgPageSuccess<List<int>>>());
    expect(c.state.dataOrNull, [1]);
    expect(c.loadMoreError, isA<Exception>());

    c.pages[2] = [2];
    await c.loadMore();
    expect(c.loadMoreError, isNull);
    expect(c.state.dataOrNull, [1, 2]);
  });

  test('a page arriving after dispose is dropped', () async {
    final page2 = Completer<List<int>>();
    final c = _Pager({
      1: [1],
      2: page2,
    });
    await c.loadInitial();

    final inFlight = c.loadMore();
    c.dispose();
    page2.complete([2]);

    await expectLater(inFlight, completes);
  });
}
