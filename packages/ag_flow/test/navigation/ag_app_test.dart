import 'dart:async';

import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Argument {
  const _Argument(this.id);
  final int id;
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

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () => AgNavigator.toNamed<void>(
          '/detail',
          arguments: const _Argument(1),
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
    final argument = AgArguments.resolve<_Argument>();
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
            AgRoute(name: '/', page: () => const _HomePage()),
            AgRoute(
              name: '/detail',
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
            AgRoute(name: '/', page: () => const _HomePage()),
            AgRoute(
              name: '/detail',
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
            AgRoute(name: '/', page: () => const _HomePage()),
            AgRoute(
              name: '/detail',
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
            AgRoute(name: '/', page: () => const _HomePage()),
            AgRoute(
              name: '/detail',
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
          '/detail',
          arguments: const _Argument(1),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        AgNavigator.toNamed<void>(
          '/detail',
          arguments: const _Argument(2),
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
            AgRoute(name: '/', page: () => const _HomePage()),
            AgRoute(
              name: '/detail',
              page: () => const _DetailPage(),
              binding: _DetailBinding(),
            ),
            AgRoute(name: '/other', page: () => const _HomePage()),
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
}
