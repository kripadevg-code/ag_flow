import 'package:ag_flow/ag_flow.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeController extends AgBaseController<List<int>> {
  _FakeController(this._fetch, {super.autoLoadOnInit});

  final Future<List<int>> Function() _fetch;
  int fetchCallCount = 0;

  @override
  Future<List<int>> fetch() {
    fetchCallCount++;
    return _fetch();
  }
}

void main() {
  group('AgBaseController lifecycle', () {
    test('starts in initial state without autoLoadOnInit', () {
      final controller = _FakeController(
        () async => [1],
        autoLoadOnInit: false,
      );
      expect(controller.state, const AgPageState<List<int>>.initial());
      expect(controller.fetchCallCount, 0);
    });

    test('onInit triggers loadInitial automatically by default', () async {
      final controller = _FakeController(() async => [1, 2, 3])..onInit();
      await Future<void>.delayed(Duration.zero);
      expect(controller.fetchCallCount, 1);
      expect(controller.state, isA<AgPageSuccess<List<int>>>());
    });

    test('loadInitial transitions loading -> success with data', () async {
      final controller = _FakeController(
        () async => [1, 2, 3],
        autoLoadOnInit: false,
      );

      final future = controller.loadInitial();
      expect(controller.state, const AgPageState<List<int>>.loading());

      await future;
      expect(controller.state, const AgPageState<List<int>>.success([1, 2, 3]));
    });

    test(
      'loadInitial transitions loading -> empty when isEmptyData is true',
      () async {
        final controller = _FakeController(
          () async => <int>[],
          autoLoadOnInit: false,
        );
        await controller.loadInitial();
        expect(controller.state, const AgPageState<List<int>>.empty());
      },
    );

    test(
      'loadInitial transitions loading -> error when fetch throws anything',
      () async {
        final controller = _FakeController(
          // A bare String is deliberately used here (not an
          // Exception/Error) to prove AG's catch is truly unconstrained,
          // per its documented contract.
          // ignore: only_throw_errors
          () async => throw 'boom',
          autoLoadOnInit: false,
        );
        await controller.loadInitial();
        expect(controller.state, isA<AgPageError<List<int>>>());
        expect((controller.state as AgPageError<List<int>>).error, 'boom');
      },
    );

    test(
      'refresh keeps previous data visible via isRefreshing while re-fetching',
      () async {
        var callCount = 0;
        final controller = _FakeController(() async {
          callCount++;
          return callCount == 1 ? [1, 2] : [3, 4];
        }, autoLoadOnInit: false);

        await controller.loadInitial();
        expect(controller.state, const AgPageState<List<int>>.success([1, 2]));

        final refreshFuture = controller.refresh();
        // Previous data must still be visible, marked as refreshing.
        expect(controller.state, isA<AgPageSuccess<List<int>>>());
        expect((controller.state as AgPageSuccess<List<int>>).data, [1, 2]);
        expect(
          (controller.state as AgPageSuccess<List<int>>).isRefreshing,
          isTrue,
        );

        await refreshFuture;
        expect(controller.state, const AgPageState<List<int>>.success([3, 4]));
      },
    );

    test(
      'refresh preserves the previous data on failure via AgPageError.previousData',
      () async {
        var callCount = 0;
        final controller = _FakeController(() async {
          callCount++;
          if (callCount == 1) return [1, 2];
          throw StateError('refresh failed');
        }, autoLoadOnInit: false);

        await controller.loadInitial();
        await controller.refresh();

        final state = controller.state;
        expect(state, isA<AgPageError<List<int>>>());
        expect((state as AgPageError<List<int>>).previousData, [1, 2]);
      },
    );

    test('retry re-runs the initial load', () async {
      final controller = _FakeController(
        () async => [9],
        autoLoadOnInit: false,
      );
      await controller.loadInitial();
      await controller.retry();
      expect(controller.fetchCallCount, 2);
    });
  });
}
