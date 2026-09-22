import 'dart:async';

import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Argument {
  const _Argument(this.id);

  factory _Argument.fromPathParameters(Map<String, String> pathParameters) =>
      _Argument(pathParameters['id']!);

  final String id;

  Map<String, String> toPathParameters() => {'id': id};
}

int _bindingRunCount = 0;
int _disposeCallCount = 0;

class _DetailBinding extends AgBinding {
  @override
  void dependencies() {
    _bindingRunCount++;
    lazyPut<_Marker>(_Marker.new);
  }

  @override
  void disposeAll() {
    _disposeCallCount++;
    super.disposeAll();
  }
}

class _Marker {}

/// A controller that records when it was disposed, so a test can check
/// *when* teardown happened rather than only that it eventually did.
class _TrackedController extends AgBaseController<String> {
  // Loads on init so the page reaches its success state; leaving it on
  // AgLoading would spin a CircularProgressIndicator forever and
  // pumpAndSettle could never settle.
  int disposeCallCount = 0;

  @override
  Future<String> fetch() async => 'ready';

  @override
  void dispose() {
    disposeCallCount++;
    super.dispose();
  }
}

class _TrackedBinding extends AgBinding {
  @override
  void dependencies() => put<_TrackedController>(_TrackedController());
}

class _TrackedPage extends AgBasePage<_TrackedController> {
  const _TrackedPage();

  @override
  Widget buildSuccess(BuildContext context) => const Text('tracked');
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () => AgNavigator.toNamed<void>(
          '/detail/:id',
          pathParameters: const _Argument('1').toPathParameters(),
        ),
        child: const Text('Go'),
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage();

  @override
  Widget build(BuildContext context) {
    final argument = _Argument.fromPathParameters(AgNavigator.pathParameters);
    return Scaffold(
      body: Column(
        children: [
          Text('id: ${argument.id}'),
          TextButton(
            onPressed: () => AgNavigator.back<void>(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUp(() {
    _bindingRunCount = 0;
    _disposeCallCount = 0;
    AgLocator.reset();
    AgNavigator.reset();
  });

  testWidgets(
    'AgNavigator.toNamed carries arguments to the pushed page with no '
    'BuildContext at the call site, and AgArguments.resolve reads them',
    (tester) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _HomePage()),
            AgRoute(
              path: '/detail/:id',
              page: () => const _DetailPage(),
              binding: _DetailBinding(),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('id: 1'), findsOneWidget);
    },
  );

  testWidgets(
    "a route's binding runs exactly once per push and is disposed exactly "
    'once per pop — pushing the same route twice runs it twice, not once',
    (tester) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _HomePage()),
            AgRoute(
              path: '/detail/:id',
              page: () => const _DetailPage(),
              binding: _DetailBinding(),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(_bindingRunCount, 1);
      expect(_disposeCallCount, 0);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(_disposeCallCount, 1);

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(_bindingRunCount, 2);
    },
  );

  testWidgets(
    "a controller-shaped dependency registered by a detail route's "
    'binding is gone from AgLocator after the route is popped',
    (tester) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _HomePage()),
            AgRoute(
              path: '/detail/:id',
              page: () => const _DetailPage(),
              binding: _DetailBinding(),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(AgLocator.find<_Marker>(), isNotNull);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(() => AgLocator.find<_Marker>(), throwsStateError);
    },
  );

  testWidgets(
    'popping one of two stacked instances of the same route keeps the '
    'shared dependencies alive for the instance still on the stack',
    (tester) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _HomePage()),
            AgRoute(
              path: '/detail/:id',
              page: () => const _DetailPage(),
              binding: _DetailBinding(),
            ),
          ],
        ),
      );

      // Push /detail twice — AgLocator is type-keyed, so both instances
      // legitimately share one set of registrations. Driven directly
      // rather than by tapping, because an opaque route takes the page
      // below it out of the tree, so its buttons aren't findable.
      // (Not awaited: toNamed's Future completes when the pushed route is
      // *popped*, so awaiting it here would hang.)
      unawaited(
        AgNavigator.toNamed<void>(
          '/detail/:id',
          pathParameters: const _Argument('1').toPathParameters(),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        AgNavigator.toNamed<void>(
          '/detail/:id',
          pathParameters: const _Argument('2').toPathParameters(),
        ),
      );
      await tester.pumpAndSettle();
      expect(_bindingRunCount, 1, reason: 'shared, so registered once');

      AgNavigator.back<void>();
      await tester.pumpAndSettle();
      expect(
        AgLocator.find<_Marker>(),
        isNotNull,
        reason: 'one instance is still on the stack and still needs it',
      );
      expect(_disposeCallCount, 0);

      AgNavigator.back<void>();
      await tester.pumpAndSettle();
      expect(_disposeCallCount, 1, reason: 'last instance gone, now torn down');
      expect(() => AgLocator.find<_Marker>(), throwsStateError);
    },
  );

  testWidgets(
    'a route left via offNamed is torn down too — Navigator reports that '
    'as didReplace, never didPop',
    (tester) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _HomePage()),
            AgRoute(
              path: '/detail/:id',
              page: () => const _DetailPage(),
              binding: _DetailBinding(),
            ),
            AgRoute(path: '/other', page: () => const _HomePage()),
          ],
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(_disposeCallCount, 0);

      // Deliberately not awaited: pushReplacementNamed's Future completes
      // when the *replacement* route is itself later popped, so awaiting
      // it here would hang rather than proceed.
      unawaited(AgNavigator.offNamed<void>('/other'));
      await tester.pumpAndSettle();

      expect(
        _disposeCallCount,
        1,
        reason: 'replacing the route must release its bindings',
      );
      expect(() => AgLocator.find<_Marker>(), throwsStateError);
    },
  );

  group('binding teardown timing', () {
    // A NavigatorObserver's didPop fires when the pop *begins*. The
    // outgoing page stays mounted and keeps reading its controller for
    // the whole exit transition, so disposing there pulls the controller
    // out from under a live widget. Teardown is driven by the route's
    // own dispose instead, which runs once the route is genuinely gone.
    testWidgets('a controller outlives the pop transition of its page', (
      tester,
    ) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _HomePage()),
            AgRoute(
              path: '/tracked',
              page: () => const _TrackedPage(),
              binding: _TrackedBinding(),
            ),
          ],
        ),
      );

      unawaited(AgNavigator.toNamed<void>('/tracked'));
      await tester.pumpAndSettle();
      final controller = AgLocator.find<_TrackedController>();
      expect(controller.disposeCallCount, 0);

      AgNavigator.back<void>();
      await tester.pump(); // the pop has started; the page is still up
      expect(
        controller.disposeCallCount,
        0,
        reason:
            'the page is still on screen and still reading this '
            'controller for the length of the exit transition',
      );
      expect(find.text('tracked'), findsOneWidget);

      await tester.pumpAndSettle(); // transition finishes, route disposed
      expect(controller.disposeCallCount, 1);
    });

    testWidgets('repeated push/pop cycles leave nothing registered', (
      tester,
    ) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _HomePage()),
            AgRoute(
              path: '/tracked',
              page: () => const _TrackedPage(),
              binding: _TrackedBinding(),
            ),
          ],
        ),
      );

      final seen = <_TrackedController>[];
      for (var i = 0; i < 5; i++) {
        unawaited(AgNavigator.toNamed<void>('/tracked'));
        await tester.pumpAndSettle();
        seen.add(AgLocator.find<_TrackedController>());
        AgNavigator.back<void>();
        await tester.pumpAndSettle();
      }

      expect(
        seen.toSet(),
        hasLength(5),
        reason: 'each push must get its own controller, never a stale one',
      );
      for (final controller in seen) {
        expect(controller.disposeCallCount, 1);
      }
      expect(AgLocator.find<_TrackedController>, throwsStateError);
    });

    testWidgets("tearing down the app disposes a live route's controller", (
      tester,
    ) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _HomePage()),
            AgRoute(
              path: '/tracked',
              page: () => const _TrackedPage(),
              binding: _TrackedBinding(),
            ),
          ],
        ),
      );
      unawaited(AgNavigator.toNamed<void>('/tracked'));
      await tester.pumpAndSettle();
      final controller = AgLocator.find<_TrackedController>();

      // The app goes away with the route still on the stack.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(
        controller.disposeCallCount,
        1,
        reason:
            'an app torn down mid-stack must still release what its '
            'live routes registered',
      );
    });
  });
}
