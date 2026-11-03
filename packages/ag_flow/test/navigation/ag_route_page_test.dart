import 'dart:async';

import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// These drive AgRoutePage through a real GoRouter, built exactly the way a
// generated app's core/routes/app_pages.dart builds one — AG owns no
// router, so this *is* the integration surface.

int _bindingRuns = 0;
int _bindingDisposals = 0;

class _Marker extends ChangeNotifier {
  @override
  void dispose() {
    _bindingDisposals++;
    super.dispose();
  }
}

/// Registers one type, then fails — a controller constructor throwing, say.
class _FailingBinding extends AgBinding {
  @override
  void dependencies() {
    put(_Marker());
    throw StateError('boom');
  }
}

class _CountingBinding extends AgBinding {
  @override
  void dependencies() {
    _bindingRuns++;
    put(_Marker());
  }
}

class _TrackedController extends AgBaseController<String> with AgRetrieve<String> {
  int disposeCalls = 0;

  @override
  Future<String> retrieve() async => 'ready';

  @override
  void dispose() {
    disposeCalls++;
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

class _ProductController extends AgBaseController<String> with AgRetrieve<String> {
  _ProductController() : id = AgRouteData.pathParameters['id']!;

  final String id;

  @override
  Future<String> retrieve() async => 'product $id';
}

class _ProductBinding extends AgBinding {
  @override
  void dependencies() => lazyPut<_ProductController>(_ProductController.new);
}

class _ProductPage extends AgBasePage<_ProductController> {
  const _ProductPage({super.key});

  @override
  Widget buildSuccess(BuildContext context) =>
      Text((controller.state as AgPageSuccess<String>).data);
}

class _Plain extends StatelessWidget {
  const _Plain(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

class _RecordingGuard extends AgGuard {
  const _RecordingGuard(this.name, {this.redirectTo});

  static final List<String> ran = [];

  final String name;
  final String? redirectTo;

  @override
  String? redirect(String path) {
    ran.add('$name:$path');
    return redirectTo;
  }
}

int _shellRuns = 0;
int _shellDisposals = 0;

class _ShellBinding extends AgBinding {
  @override
  void dependencies() {
    _shellRuns++;
    put(_ShellMarker());
  }
}

class _ShellMarker extends ChangeNotifier {
  @override
  void dispose() {
    _shellDisposals++;
    super.dispose();
  }
}

/// One route, written the way the generator writes it.
GoRoute _route(
  String path,
  Widget Function(GoRouterState state) page, {
  AgBinding Function()? binding,
  List<AgGuard> guards = const [],
}) {
  return GoRoute(
    path: path,
    name: path,
    redirect: guards.isEmpty ? null : (context, state) => AgGuard.check(guards, state.fullPath!),
    pageBuilder: (context, state) => AgRoutePage<void>(
      key: state.pageKey,
      pathParameters: state.pathParameters,
      extra: state.extra,
      binding: binding?.call(),
      child: page(state),
    ),
  );
}

late GoRouter _router;

Future<void> _pumpApp(
  WidgetTester tester,
  List<RouteBase> routes, {
  String initialLocation = '/',
}) async {
  _router = GoRouter(initialLocation: initialLocation, routes: routes);
  addTearDown(_router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: _router));
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, String location) async {
  unawaited(_router.push<void>(location));
  await tester.pumpAndSettle();
}

Future<void> _pop(WidgetTester tester) async {
  _router.pop<void>();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _bindingRuns = 0;
    _bindingDisposals = 0;
    _shellRuns = 0;
    _shellDisposals = 0;
    _RecordingGuard.ran.clear();
    AgLocator.reset();
    AgRouteData.reset();
  });

  test('a binding that throws mid-registration leaves nothing behind', () {
    expect(() => AgBinding.acquire(_FailingBinding()), throwsStateError);
    expect(AgLocator.find<_Marker>, throwsStateError);
  });

  group('binding lifecycle', () {
    final routes = [
      _route('/', (_) => const _Plain('home')),
      _route(
        '/detail',
        (_) => const _Plain('detail'),
        binding: _CountingBinding.new,
      ),
      _route('/other', (_) => const _Plain('other')),
    ];

    testWidgets('registers on push, tears down on pop, re-runs on re-push', (
      tester,
    ) async {
      await _pumpApp(tester, routes);

      await _push(tester, '/detail');
      expect(_bindingRuns, 1);
      expect(AgLocator.find<_Marker>(), isNotNull);

      await _pop(tester);
      expect(_bindingDisposals, 1);
      expect(AgLocator.find<_Marker>, throwsStateError);

      await _push(tester, '/detail');
      expect(_bindingRuns, 2);
    });

    testWidgets(
      'a rebuild handing over a fresh binding instance does not register '
      'twice — the route keeps its first scope',
      (tester) async {
        await _pumpApp(tester, routes);
        await _push(tester, '/detail');

        // Makes go_router rebuild its pages, calling pageBuilder (and so
        // `_CountingBinding.new`) again.
        _router.refresh();
        await tester.pumpAndSettle();

        expect(_bindingRuns, 1);
        await _pop(tester);
        expect(_bindingDisposals, 1);
        expect(AgLocator.find<_Marker>, throwsStateError);
      },
    );

    testWidgets(
      'two stacked instances each get their own registration, and popping '
      'one releases only its own',
      (tester) async {
        await _pumpApp(tester, routes);
        await _push(tester, '/detail');
        final first = AgLocator.find<_Marker>();
        await _push(tester, '/detail');
        expect(_bindingRuns, 2);
        expect(AgLocator.find<_Marker>(), isNot(same(first)));

        await _pop(tester);
        expect(_bindingDisposals, 1);
        expect(AgLocator.find<_Marker>(), same(first));

        await _pop(tester);
        expect(_bindingDisposals, 2, reason: 'last instance gone');
        expect(AgLocator.find<_Marker>, throwsStateError);
      },
    );

    testWidgets(
      'a route left via pushReplacement is torn down — the generated '
      'navigation never uses replace, which would reuse the page key',
      (tester) async {
        await _pumpApp(tester, routes);
        await _push(tester, '/detail');

        unawaited(_router.pushReplacement<void>('/other'));
        await tester.pumpAndSettle();

        expect(find.text('other'), findsOneWidget);
        expect(_bindingDisposals, 1);
        expect(AgLocator.find<_Marker>, throwsStateError);
      },
    );
  });

  group('teardown timing', () {
    final routes = [
      _route('/', (_) => const _Plain('home')),
      _route(
        '/tracked',
        (_) => const _TrackedPage(),
        binding: _TrackedBinding.new,
      ),
    ];

    testWidgets('a controller outlives the pop transition of its page', (
      tester,
    ) async {
      await _pumpApp(tester, routes);
      await _push(tester, '/tracked');
      final controller = AgLocator.find<_TrackedController>();

      _router.pop<void>();
      await tester.pump(); // the pop has started; the page is still up
      expect(
        controller.disposeCalls,
        0,
        reason:
            'the page is still on screen and still reading this controller '
            'for the length of the exit transition',
      );
      expect(find.text('tracked'), findsOneWidget);

      await tester.pumpAndSettle(); // transition done, route disposed
      expect(controller.disposeCalls, 1);
    });

    testWidgets('repeated push/pop cycles leave nothing registered', (
      tester,
    ) async {
      await _pumpApp(tester, routes);
      final controllers = <_TrackedController>[];
      for (var i = 0; i < 3; i++) {
        await _push(tester, '/tracked');
        controllers.add(AgLocator.find<_TrackedController>());
        await _pop(tester);
      }

      expect(controllers.toSet(), hasLength(3), reason: 'fresh each push');
      for (final controller in controllers) {
        expect(controller.disposeCalls, 1);
      }
      expect(AgLocator.find<_TrackedController>, throwsStateError);
    });

    testWidgets("tearing down the app disposes a live route's controller", (
      tester,
    ) async {
      await _pumpApp(tester, routes);
      await _push(tester, '/tracked');
      final controller = AgLocator.find<_TrackedController>();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(controller.disposeCalls, 1);
    });
  });

  group('route data', () {
    final routes = [
      _route('/', (_) => const _Plain('home')),
      _route(
        '/product/:id',
        (state) => _ProductPage(key: state.pageKey),
        binding: _ProductBinding.new,
      ),
    ];

    testWidgets('a cold start straight at a detail URL resolves its argument', (
      tester,
    ) async {
      await _pumpApp(tester, routes, initialLocation: '/product/42');
      expect(find.text('product 42'), findsOneWidget);
    });

    testWidgets('an in-app push carries the argument in the path', (
      tester,
    ) async {
      await _pumpApp(tester, routes);
      unawaited(
        _router.pushNamed<void>(
          '/product/:id',
          pathParameters: const {'id': '7'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('product 7'), findsOneWidget);
    });

    testWidgets('product 7 under product 9: each page keeps its own controller', (
      tester,
    ) async {
      await _pumpApp(tester, routes);
      await _push(tester, '/product/7');
      final seven = AgLocator.find<_ProductController>();
      await _push(tester, '/product/9');
      final nine = AgLocator.find<_ProductController>();
      expect(nine, isNot(same(seven)));
      expect(find.text('product 9'), findsOneWidget);

      // The covered page rebuilds while 9 is on top: it must still read 7.
      await seven.refresh();
      await tester.pump();

      await _pop(tester);
      expect(find.text('product 7'), findsOneWidget);
      expect(seven.isDisposed, isFalse);
      expect(nine.isDisposed, isTrue);
      expect(AgLocator.find<_ProductController>(), same(seven));
    });

    testWidgets('one const page shown by two live routes is reported', (tester) async {
      await _pumpApp(tester, [
        _route('/', (_) => const _Plain('home')),
        _route('/tracked', (_) => const _TrackedPage(), binding: _TrackedBinding.new),
      ]);
      await _push(tester, '/tracked');
      await _push(tester, '/tracked');

      expect(tester.takeException().toString(), contains('two routes at once'));
    });
  });

  group('AgGuard.check', () {
    testWidgets('guards run in order and the first redirect wins', (
      tester,
    ) async {
      await _pumpApp(tester, [
        _route('/', (_) => const _Plain('home')),
        _route(
          '/admin',
          (_) => const _Plain('admin'),
          guards: const [
            _RecordingGuard('auth'),
            _RecordingGuard('role', redirectTo: '/'),
            _RecordingGuard('never'),
          ],
        ),
      ]);

      _router.go('/admin');
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(_RecordingGuard.ran, ['auth:/admin', 'role:/admin']);
    });

    testWidgets('a blocked route never registers its binding', (tester) async {
      await _pumpApp(tester, [
        _route('/', (_) => const _Plain('home')),
        _route(
          '/product/:id',
          (state) => _ProductPage(key: state.pageKey),
          binding: _ProductBinding.new,
          guards: const [_RecordingGuard('block', redirectTo: '/')],
        ),
      ]);

      _router.go('/product/1');
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(AgLocator.find<_ProductController>, throwsStateError);
    });
  });

  testWidgets(
    'AgShellScope keeps a binding alive across the routes inside a '
    'ShellRoute, and releases it on leaving',
    (tester) async {
      await _pumpApp(tester, initialLocation: '/a', [
        ShellRoute(
          builder: (context, state, child) => AgShellScope(
            binding: _ShellBinding(),
            child: Scaffold(
              body: child,
              bottomNavigationBar: const Text('nav'),
            ),
          ),
          routes: [
            _route('/a', (_) => const Text('page-a')),
            _route('/b', (_) => const Text('page-b')),
          ],
        ),
        _route('/outside', (_) => const _Plain('outside')),
      ]);
      expect(find.text('page-a'), findsOneWidget);
      expect(_shellRuns, 1);

      _router.go('/b');
      await tester.pumpAndSettle();
      expect(find.text('nav'), findsOneWidget);
      expect(find.text('page-b'), findsOneWidget);
      expect(_shellRuns, 1, reason: 'never re-entered, never re-run');
      expect(_shellDisposals, 0);

      _router.go('/outside');
      await tester.pumpAndSettle();
      expect(find.text('nav'), findsNothing);
      expect(_shellDisposals, 1);
    },
  );
}
