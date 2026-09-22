import 'dart:async';

import 'package:ag_flow/ag_flow.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestListController extends AgListController<int, int> {
  _TestListController(this._fetchPage)
    : super(initialPageKey: 1, autoLoadOnInit: false);

  final Future<AgListPage<int, int>> Function(int pageKey) _fetchPage;
  int fetchPageCallCount = 0;

  @override
  Future<AgListPage<int, int>> fetchPage(int pageKey) {
    fetchPageCallCount++;
    return _fetchPage(pageKey);
  }

  void applyUpdateItems(List<int> Function(List<int> items) transform) =>
      updateItems(transform);
}

void main() {
  group('AgPaginationMixin', () {
    test(
      'loadInitial seeds items, nextPageKey, and hasNextPage from the first page',
      () async {
        final controller = _TestListController(
          (pageKey) async => AgListPage(
            items: const [1, 2, 3],
            hasMore: true,
            nextPageKey: pageKey + 1,
          ),
        );

        await controller.loadInitial();

        expect(controller.pagination.items, [1, 2, 3]);
        expect(controller.pagination.hasNextPage, isTrue);
        expect(controller.pagination.nextPageKey, 2);
        expect(controller.state, isA<AgPageSuccess<List<int>>>());
      },
    );

    test('loadMore appends the next page and advances nextPageKey', () async {
      final controller = _TestListController((pageKey) async {
        if (pageKey == 1) {
          return const AgListPage(items: [1, 2], hasMore: true, nextPageKey: 2);
        }
        return const AgListPage(items: [3, 4], hasMore: false);
      });

      await controller.loadInitial();
      await controller.loadMore();

      expect(controller.pagination.items, [1, 2, 3, 4]);
      expect(controller.pagination.hasNextPage, isFalse);
      expect(controller.pagination.isLoadingMore, isFalse);
    });

    test('loadMore is a no-op once hasNextPage is false', () async {
      final controller = _TestListController(
        (pageKey) async => const AgListPage(items: [1], hasMore: false),
      );

      await controller.loadInitial();
      await controller.loadMore();
      await controller.loadMore();

      expect(controller.fetchPageCallCount, 1);
      expect(controller.pagination.items, [1]);
    });

    test(
      'concurrent loadMore calls only trigger a single underlying fetch',
      () async {
        final controller = _TestListController((pageKey) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return AgListPage(
            items: [pageKey],
            hasMore: true,
            nextPageKey: pageKey + 1,
          );
        });

        await controller.loadInitial();
        expect(controller.fetchPageCallCount, 1);

        // Fire multiple overlapping loadMore calls, as a fast scroll-listener
        // burst would — the isLoadingMore guard must collapse these to one.
        final futures = [
          controller.loadMore(),
          controller.loadMore(),
          controller.loadMore(),
        ];
        await Future.wait(futures);

        expect(controller.fetchPageCallCount, 2);
      },
    );

    test(
      'a load-more failure sets pagination.loadMoreError while the page-level state stays '
      'AgPageSuccess — initial-load and load-more errors are distinct (ag_framework.md §52)',
      () async {
        var callCount = 0;
        final controller = _TestListController((pageKey) async {
          callCount++;
          if (callCount == 1) {
            return const AgListPage(
              items: [1, 2],
              hasMore: true,
              nextPageKey: 2,
            );
          }
          throw StateError('load more failed');
        });

        await controller.loadInitial();
        await controller.loadMore();

        expect(controller.state, isA<AgPageSuccess<List<int>>>());
        expect((controller.state as AgPageSuccess<List<int>>).data, [1, 2]);
        expect(controller.pagination.loadMoreError, isA<StateError>());
        expect(controller.pagination.isLoadingMore, isFalse);
      },
    );

    test(
      'retryLoadMore re-attempts the same page after a load-more failure',
      () async {
        var callCount = 0;
        final controller = _TestListController((pageKey) async {
          callCount++;
          if (callCount == 1) {
            return const AgListPage(items: [1], hasMore: true, nextPageKey: 2);
          }
          if (callCount == 2) throw StateError('boom');
          return const AgListPage(items: [2], hasMore: false);
        });

        await controller.loadInitial();
        await controller.loadMore();
        expect(controller.pagination.loadMoreError, isNotNull);

        await controller.retryLoadMore();
        expect(controller.pagination.loadMoreError, isNull);
        expect(controller.pagination.items, [1, 2]);
      },
    );

    test(
      'refresh resets pagination before re-fetching the first page',
      () async {
        final controller = _TestListController(
          (pageKey) async => AgListPage(
            items: [pageKey],
            hasMore: true,
            nextPageKey: pageKey + 1,
          ),
        );

        await controller.loadInitial();
        await controller.loadMore();
        expect(controller.pagination.items, [1, 2]);

        await controller.refresh();
        expect(controller.pagination.items, [1]);
        expect(controller.pagination.hasNextPage, isTrue);
      },
    );

    test(
      'updateItems lets a subclass reflect a mutation locally without a '
      'full re-fetch',
      () async {
        final controller = _TestListController(
          (pageKey) async => const AgListPage(items: [1, 2, 3], hasMore: false),
        );
        await controller.loadInitial();

        controller.applyUpdateItems((items) => [99, ...items]);
        expect(controller.pagination.items, [99, 1, 2, 3]);

        controller.applyUpdateItems(
          (items) => items.where((i) => i != 2).toList(),
        );
        expect(controller.pagination.items, [99, 1, 3]);
        // Untouched by an items-only transform.
        expect(controller.pagination.hasNextPage, isFalse);
      },
    );
  });

  group('refresh racing an in-flight loadMore', () {
    // Pulling to refresh while a load-more is already in flight is
    // ordinary use. The in-flight page belongs to the list as it was
    // *before* the refresh — appending it afterwards splices stale rows
    // into freshly loaded ones.
    test('a page that arrives after a refresh is discarded', () async {
      final pending = <Completer<AgListPage<int, int>>>[];
      final controller = _TestListController((pageKey) {
        final completer = Completer<AgListPage<int, int>>();
        pending.add(completer);
        return completer.future;
      });

      unawaited(controller.loadInitial());
      pending[0].complete(
        const AgListPage(items: [1, 2], hasMore: true, nextPageKey: 2),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.pagination.items, [1, 2]);

      unawaited(controller.loadMore()); // pending[1]
      unawaited(controller.refresh()); // pending[2] — supersedes it

      pending[2].complete(const AgListPage(items: [9], hasMore: false));
      await Future<void>.delayed(Duration.zero);
      pending[1].complete(
        const AgListPage(items: [3, 4], hasMore: true, nextPageKey: 3),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.pagination.items, [9]);
      expect(
        controller.pagination.isLoadingMore,
        isFalse,
        reason: 'a discarded page must not leave a spinner stuck on screen',
      );
      controller.dispose();
    });

    test('a load-more that fails after a refresh reports no error', () async {
      final pending = <Completer<AgListPage<int, int>>>[];
      final controller = _TestListController((pageKey) {
        final completer = Completer<AgListPage<int, int>>();
        pending.add(completer);
        return completer.future;
      });

      unawaited(controller.loadInitial());
      pending[0].complete(
        const AgListPage(items: [1], hasMore: true, nextPageKey: 2),
      );
      await Future<void>.delayed(Duration.zero);

      unawaited(controller.loadMore()); // pending[1]
      unawaited(controller.refresh()); // pending[2]
      pending[2].complete(const AgListPage(items: [5], hasMore: false));
      await Future<void>.delayed(Duration.zero);
      pending[1].completeError(Exception('stale load-more failure'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.pagination.items, [5]);
      expect(controller.pagination.loadMoreError, isNull);
      controller.dispose();
    });
  });
}
