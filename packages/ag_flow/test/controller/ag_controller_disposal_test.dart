import 'package:ag_flow/ag_flow.dart';
import 'package:flutter_test/flutter_test.dart';

class _SlowController extends AgBaseController<List<int>> {
  _SlowController() : super(autoLoadOnInit: false);

  @override
  Future<List<int>> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return [1, 2, 3];
  }
}

class _SlowListController extends AgListController<int, int> {
  _SlowListController() : super(initialPageKey: 1, autoLoadOnInit: false);

  @override
  Future<AgListPage<int, int>> fetchPage(int pageKey) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return const AgListPage(items: [1, 2], hasMore: false);
  }
}

class _FailingController extends AgBaseController<List<int>> {
  _FailingController() : super(autoLoadOnInit: false);

  @override
  Future<List<int>> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    throw StateError('backend exploded');
  }
}

/// Backing out of a screen while its first load is still in flight is a
/// completely ordinary thing for a user to do — not an edge case. Because
/// `AgBaseController` is a `ChangeNotifier`, and a popped route's
/// controller is disposed by its `AgBinding`, an unguarded `emit()` from
/// the late-arriving `fetch()` would throw a "was used after being
/// disposed" error straight out of an untracked async gap.
void main() {
  setUp(AgLocator.reset);

  test('a fetch completing after dispose is silently dropped', () async {
    final controller = _SlowController();
    final inFlight = controller.loadInitial();
    controller.dispose();

    await expectLater(inFlight, completes);
    expect(controller.isDisposed, isTrue);
    expect(
      controller.state,
      isA<AgPageLoading<List<int>>>(),
      reason: 'state must not advance past where it was at disposal',
    );
  });

  test('a fetch *failing* after dispose is dropped just as quietly', () async {
    final controller = _FailingController();
    final inFlight = controller.loadInitial();
    controller.dispose();

    await expectLater(inFlight, completes);
    expect(controller.state, isA<AgPageLoading<List<int>>>());
  });

  test(
    'a paginated fetchPage completing after dispose is dropped — the '
    'pagination notifier has the same lifetime as the controller',
    () async {
      final controller = _SlowListController();
      final inFlight = controller.loadInitial();
      controller.dispose();

      await expectLater(inFlight, completes);
      expect(controller.pagination.items, isEmpty);
    },
  );

  test(
    'AgLocator.delete disposes a realized controller rather than just '
    'dropping the reference — otherwise every popped route leaks its '
    'listeners',
    () {
      final controller = _SlowController();
      AgLocator.put<_SlowController>(controller);

      AgLocator.delete<_SlowController>();

      expect(controller.isDisposed, isTrue);
    },
  );

  test('a permanent registration is never disposed by delete', () {
    final controller = _SlowController();
    AgLocator.put<_SlowController>(controller, permanent: true);

    AgLocator.delete<_SlowController>();

    expect(controller.isDisposed, isFalse);
    expect(AgLocator.find<_SlowController>(), same(controller));
  });

  test('a never-realized lazyPut factory has nothing to dispose', () {
    var built = 0;
    AgLocator.lazyPut<_SlowController>(() {
      built++;
      return _SlowController();
    });

    AgLocator.delete<_SlowController>();

    expect(built, 0);
  });
}
