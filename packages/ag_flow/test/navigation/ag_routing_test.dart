import 'dart:async';

import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A detail module's argument, in the shape the generator now emits:
/// built from the route's path parameters, and convertible back to them.
class _ProductArgument {
  const _ProductArgument({required this.id});

  factory _ProductArgument.fromPathParameters(Map<String, String> params) =>
      _ProductArgument(id: params['id']!);

  final String id;

  Map<String, String> toPathParameters() => {'id': id};
}

class _ProductController extends AgDetailController<String, _ProductArgument> {
  @override
  _ProductArgument? argumentsFromPath(Map<String, String> pathParameters) =>
      _ProductArgument.fromPathParameters(pathParameters);

  @override
  Future<String> fetch() async => 'product ${arguments.id}';
}

class _ProductBinding extends AgBinding {
  @override
  void dependencies() => put<_ProductController>(_ProductController());
}

class _ProductPage extends AgBasePage<_ProductController> {
  const _ProductPage({super.key});

  @override
  Widget buildSuccess(BuildContext context) =>
      Text(controller.state.dataOrNull!);
}

class _Plain extends StatelessWidget {
  const _Plain(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

/// Records the order guards ran in, and redirects when told to.
class _RecordingGuard extends AgGuard {
  _RecordingGuard(this.label, {this.redirectTo});

  final String label;
  final String? redirectTo;
  static final List<String> ran = [];

  @override
  String? redirect(String path) {
    ran.add('$label:$path');
    return redirectTo;
  }
}

int _shellBindingRuns = 0;
int _shellBindingDisposals = 0;

class _ShellMarker {}

class _ShellBinding extends AgBinding {
  @override
  void dependencies() {
    _shellBindingRuns++;
    put<_ShellMarker>(_ShellMarker());
  }

  @override
  void disposeAll() {
    _shellBindingDisposals++;
    super.disposeAll();
  }
}

void main() {
  setUp(() {
    AgLocator.reset();
    AgNavigator.reset();
    _RecordingGuard.ran.clear();
    _shellBindingRuns = 0;
    _shellBindingDisposals = 0;
  });

  group('deep links', () {
    testWidgets('a cold start straight at a detail URL resolves its argument', (
      tester,
    ) async {
      // No in-app push happened at all — this is the notification /
      // shared-link / browser-reload case that an opaque argument object
      // could never survive.
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/product/42',
          routes: [
            AgRoute(path: '/', page: () => const _Plain('home')),
            AgRoute(
              path: '/product/:id',
              page: _ProductPage.new,
              binding: _ProductBinding(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('product 42'), findsOneWidget);
      expect(
        AgNavigator.location,
        '/product/42',
        reason: 'the page is at a real, shareable URL',
      );
    });

    testWidgets('navigating in-app puts the argument in the URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _Plain('home')),
            AgRoute(
              path: '/product/:id',
              page: _ProductPage.new,
              binding: _ProductBinding(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      unawaited(
        AgNavigator.toNamed<void>(
          '/product/:id',
          pathParameters: const _ProductArgument(id: '7').toPathParameters(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('product 7'), findsOneWidget);
    });
  });

  group('guards', () {
    testWidgets('run in order, and the first redirect wins', (tester) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _Plain('home')),
            AgRoute(
              path: '/admin',
              page: () => const _Plain('admin'),
              guards: [
                _RecordingGuard('auth'),
                _RecordingGuard('role', redirectTo: '/'),
                _RecordingGuard('never'),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      AgNavigator.offAllNamed('/admin');
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('admin'), findsNothing);
      expect(
        _RecordingGuard.ran,
        ['auth:/admin', 'role:/admin'],
        reason:
            'guards run in order and stop at the first redirect; the '
            'path they see is the route template, so it compares directly '
            'against the AppRoutes constant',
      );
    });

    testWidgets('a blocked route never registers its binding', (tester) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/',
          routes: [
            AgRoute(path: '/', page: () => const _Plain('home')),
            AgRoute(
              path: '/product/:id',
              page: _ProductPage.new,
              binding: _ProductBinding(),
              guards: [_RecordingGuard('block', redirectTo: '/')],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      AgNavigator.offAllNamed(
        '/product/:id',
        pathParameters: const {'id': '1'},
      );
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(
        AgLocator.find<_ProductController>,
        throwsStateError,
        reason:
            'a page that was never built must not leave a controller '
            'registered behind it',
      );
    });
  });

  group('AgShellRoute', () {
    testWidgets('chrome and its binding persist across child routes', (
      tester,
    ) async {
      await tester.pumpWidget(
        AgApp(
          initialRoute: '/a',
          routes: [
            AgShellRoute(
              binding: _ShellBinding(),
              builder: (context, child) => Scaffold(
                body: child,
                bottomNavigationBar: const Text('nav'),
              ),
              routes: [
                AgRoute(path: '/a', page: () => const Text('page-a')),
                AgRoute(path: '/b', page: () => const Text('page-b')),
              ],
            ),
            AgRoute(path: '/outside', page: () => const _Plain('outside')),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('nav'), findsOneWidget);
      expect(find.text('page-a'), findsOneWidget);
      expect(_shellBindingRuns, 1);

      AgNavigator.offAllNamed('/b');
      await tester.pumpAndSettle();
      expect(find.text('nav'), findsOneWidget, reason: 'chrome persists');
      expect(find.text('page-b'), findsOneWidget);
      expect(
        _shellBindingRuns,
        1,
        reason: 'the shell was never re-entered, so its binding never re-ran',
      );
      expect(_shellBindingDisposals, 0);

      AgNavigator.offAllNamed('/outside');
      await tester.pumpAndSettle();
      expect(find.text('nav'), findsNothing);
      expect(
        _shellBindingDisposals,
        1,
        reason: "leaving the shell releases what the shell's binding owned",
      );
    });
  });

  testWidgets('an unmatched location shows the error page, not a crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      AgApp(
        initialRoute: '/',
        routes: [AgRoute(path: '/', page: () => const _Plain('home'))],
        errorBuilder: (context, location) =>
            Scaffold(body: Text('no route for $location')),
      ),
    );
    await tester.pumpAndSettle();

    AgNavigator.toLocation('/does-not-exist');
    await tester.pumpAndSettle();

    expect(find.text('no route for /does-not-exist'), findsOneWidget);
  });
}
