import 'dart:async';

import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestListController extends AgListController<int, int> {
  _TestListController(this._fetchPage)
    : super(initialPageKey: 1, autoLoadOnInit: false);

  final Future<AgListPage<int, int>> Function(int pageKey) _fetchPage;
  int retryLoadMoreCallCount = 0;
  int fetchPageCallCount = 0;

  @override
  Future<AgListPage<int, int>> fetchPage(int pageKey) {
    fetchPageCallCount++;
    return _fetchPage(pageKey);
  }

  @override
  Future<void> retryLoadMore() {
    retryLoadMoreCallCount++;
    return super.retryLoadMore();
  }
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AgListBuilder', () {
    testWidgets('renders one widget per item via itemBuilder', (
      tester,
    ) async {
      final controller = _TestListController(
        (pageKey) async => const AgListPage(items: [1, 2, 3], hasMore: false),
      );
      await controller.loadInitial();

      await tester.pumpWidget(
        _wrap(
          AgListBuilder<int, int>(
            controller: controller,
            itemBuilder: (context, item, index) => Text('item-$item'),
          ),
        ),
      );

      expect(find.text('item-1'), findsOneWidget);
      expect(find.text('item-2'), findsOneWidget);
      expect(find.text('item-3'), findsOneWidget);
    });

    testWidgets('uses separatorBuilder between items when provided', (
      tester,
    ) async {
      final controller = _TestListController(
        (pageKey) async => const AgListPage(items: [1, 2], hasMore: false),
      );
      await controller.loadInitial();

      await tester.pumpWidget(
        _wrap(
          AgListBuilder<int, int>(
            controller: controller,
            itemBuilder: (context, item, index) => Text('item-$item'),
            separatorBuilder: (context, index) =>
                const Divider(key: Key('sep')),
          ),
        ),
      );

      expect(find.byKey(const Key('sep')), findsOneWidget);
    });

    testWidgets(
      'shows the AG default load-more indicator while a load-more fetch '
      'is in flight, with no override supplied',
      (tester) async {
        final secondPage = Completer<AgListPage<int, int>>();
        final controller = _TestListController((pageKey) {
          if (pageKey == 1) {
            return Future.value(
              const AgListPage(items: [1], hasMore: true, nextPageKey: 2),
            );
          }
          return secondPage.future;
        });
        await controller.loadInitial();
        unawaited(controller.loadMore());
        expect(controller.pagination.isLoadingMore, isTrue);

        await tester.pumpWidget(
          _wrap(
            AgListBuilder<int, int>(
              controller: controller,
              itemBuilder: (context, item, index) => Text('item-$item'),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        secondPage.complete(const AgListPage(items: [2], hasMore: false));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('renders a custom loadMoreBuilder override when supplied', (
      tester,
    ) async {
      final secondPage = Completer<AgListPage<int, int>>();
      final controller = _TestListController((pageKey) {
        if (pageKey == 1) {
          return Future.value(
            const AgListPage(items: [1], hasMore: true, nextPageKey: 2),
          );
        }
        return secondPage.future;
      });
      await controller.loadInitial();
      unawaited(controller.loadMore());

      await tester.pumpWidget(
        _wrap(
          AgListBuilder<int, int>(
            controller: controller,
            itemBuilder: (context, item, index) => Text('item-$item'),
            loadMoreBuilder: (context) => const Text('custom-loading'),
          ),
        ),
      );

      expect(find.text('custom-loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      secondPage.complete(const AgListPage(items: [2], hasMore: false));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'shows the AG default load-more error and retries via the '
      'controller when tapped',
      (tester) async {
        final controller = _TestListController((pageKey) async {
          if (pageKey == 1) {
            return const AgListPage(items: [1], hasMore: true, nextPageKey: 2);
          }
          throw StateError('boom');
        });
        await controller.loadInitial();
        await controller.loadMore();

        await tester.pumpWidget(
          _wrap(
            AgListBuilder<int, int>(
              controller: controller,
              itemBuilder: (context, item, index) => Text('item-$item'),
            ),
          ),
        );

        expect(find.textContaining('Failed to load more'), findsOneWidget);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));

        expect(controller.retryLoadMoreCallCount, 1);
      },
    );

    testWidgets(
      'renders a custom loadMoreErrorBuilder override when supplied',
      (
        tester,
      ) async {
        final controller = _TestListController((pageKey) async {
          if (pageKey == 1) {
            return const AgListPage(items: [1], hasMore: true, nextPageKey: 2);
          }
          throw StateError('boom');
        });
        await controller.loadInitial();
        await controller.loadMore();

        await tester.pumpWidget(
          _wrap(
            AgListBuilder<int, int>(
              controller: controller,
              itemBuilder: (context, item, index) => Text('item-$item'),
              loadMoreErrorBuilder: (context, error, retry) =>
                  Text('custom-error: $error'),
            ),
          ),
        );

        expect(find.text('custom-error: Bad state: boom'), findsOneWidget);
      },
    );

    testWidgets(
      'renders nothing extra when the list is exhausted and no '
      'noMoreItemsBuilder is supplied',
      (tester) async {
        final controller = _TestListController(
          (pageKey) async => const AgListPage(items: [1], hasMore: false),
        );
        await controller.loadInitial();

        await tester.pumpWidget(
          _wrap(
            AgListBuilder<int, int>(
              controller: controller,
              itemBuilder: (context, item, index) => Text('item-$item'),
            ),
          ),
        );

        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.text('item-1'), findsOneWidget);
      },
    );

    testWidgets('renders a custom noMoreItemsBuilder override when supplied', (
      tester,
    ) async {
      final controller = _TestListController(
        (pageKey) async => const AgListPage(items: [1], hasMore: false),
      );
      await controller.loadInitial();

      await tester.pumpWidget(
        _wrap(
          AgListBuilder<int, int>(
            controller: controller,
            itemBuilder: (context, item, index) => Text('item-$item'),
            noMoreItemsBuilder: (context) => const Text('the-end'),
          ),
        ),
      );

      expect(find.text('the-end'), findsOneWidget);
    });
  });

  group('scroll-driven load-more', () {
    // 30 rows of 100px in a 300px viewport: far from the bottom, so
    // nothing should load until the user actually scrolls down there.
    Future<AgListPage<int, int>> longPage(int pageKey) async => AgListPage(
      items: List<int>.generate(30, (i) => pageKey * 100 + i),
      hasMore: true,
      nextPageKey: pageKey + 1,
    );

    testWidgets('a nested scrollable does not load pages of the outer list', (
      tester,
    ) async {
      final controller = _TestListController(longPage);
      await controller.loadInitial();

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 300,
            child: AgListBuilder<int, int>(
              controller: controller,
              itemBuilder: (context, item, index) => SizedBox(
                height: 100,
                // A horizontal carousel inside a row — its own metrics
                // always read as "near the bottom", and they bubble up
                // to the outer list's NotificationListener.
                child: ListView(
                  key: ValueKey('inner-$index'),
                  scrollDirection: Axis.horizontal,
                  children: List<Widget>.generate(
                    2,
                    (i) => const SizedBox(width: 420, height: 100),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fetchesBefore = controller.fetchPageCallCount;

      await tester.drag(
        find.byKey(const ValueKey('inner-0')),
        const Offset(-30, 0),
      );
      await tester.pumpAndSettle();

      expect(controller.fetchPageCallCount, fetchesBefore);
      controller.dispose();
    });

    testWidgets('a failed page is not retried by continued scrolling', (
      tester,
    ) async {
      var calls = 0;
      final controller = _TestListController((pageKey) async {
        calls++;
        if (pageKey == 1) {
          return AgListPage(
            items: List<int>.generate(30, (i) => i),
            hasMore: true,
            nextPageKey: 2,
          );
        }
        throw Exception('backend is down');
      });
      await controller.loadInitial();

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 300,
            child: AgListBuilder<int, int>(
              controller: controller,
              itemBuilder: (context, item, index) =>
                  SizedBox(height: 100, child: Text('item-$item')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to the bottom so load-more fires and fails.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(controller.pagination.loadMoreError, isNotNull);
      final callsAfterFailure = calls;

      // Keep scrolling around at the bottom. Every frame of this would
      // re-issue the failed request if the error were not latched.
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      expect(
        calls,
        callsAfterFailure,
        reason:
            'a backend that is already failing must not be retried once '
            'per scroll frame — recovery is the deliberate retryLoadMore()',
      );
      controller.dispose();
    });
  });
}
