import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Auth extends AgAuth {
  String? token;
  int clears = 0;
  int logouts = 0;
  bool clearThrows = false;

  @override
  String? readToken() => token;

  @override
  void clearToken() {
    clears++;
    token = null;
    if (clearThrows) throw StateError('storage locked');
  }

  @override
  void onLoggedOut() => logouts++;
}

_Auth _auth() {
  final auth = _Auth();
  addTearDown(auth.dispose);
  return auth;
}

void main() {
  group('AgAuth session', () {
    test('restoreSession reads the stored token', () async {
      final auth = _auth()..token = 't';
      var notified = 0;
      auth.addListener(() => notified++);

      await auth.restoreSession();
      expect(auth.isLoggedIn, isTrue);
      expect(notified, 1);

      auth.token = null;
      await auth.restoreSession();
      expect(auth.isLoggedIn, isFalse);
      expect(notified, 2);
    });

    test('logIn and logOut notify only when the state changes', () async {
      var notified = 0;
      final auth = _auth()
        ..addListener(() => notified++)
        ..logIn()
        ..logIn();
      expect(auth.isLoggedIn, isTrue);
      expect(notified, 1);

      await auth.logOut();
      await auth.logOut();
      expect(auth.isLoggedIn, isFalse);
      expect(notified, 2);
    });

    test('logOut clears the token, then calls onLoggedOut', () async {
      final auth = _auth()
        ..token = 't'
        ..logIn();

      await auth.logOut();

      expect(auth.token, isNull);
      expect(auth.clears, 1);
      expect(auth.logouts, 1);
    });

    test('logOut still ends the session when clearToken throws', () async {
      final auth = _auth()
        ..clearThrows = true
        ..logIn();

      await expectLater(auth.logOut(), throwsStateError);

      expect(auth.isLoggedIn, isFalse);
      expect(auth.logouts, 1);
    });
  });

  group('AgAuthGuard', () {
    test('sends a logged-out user to the login path', () {
      final auth = _auth();
      final guard = AgAuthGuard(auth, loginPath: '/login');

      expect(guard.redirect('/home'), '/login');
      expect(guard.redirect('/login'), isNull);

      auth.logIn();
      expect(guard.redirect('/home'), isNull);
    });

    testWidgets('a logOut moves the router off a protected route', (tester) async {
      final auth = _auth()..logIn();
      final guard = AgAuthGuard(auth, loginPath: '/login');
      final router = GoRouter(
        initialLocation: '/home',
        refreshListenable: auth,
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const Text('login')),
          GoRoute(
            path: '/home',
            redirect: (_, state) => AgGuard.check([guard], state.fullPath!),
            builder: (_, _) => const Text('home'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.text('home'), findsOneWidget);

      await auth.logOut();
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
      expect(find.text('home'), findsNothing);

      auth.logIn();
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('a logged-out start opens the login route', (tester) async {
      final auth = _auth();
      final router = GoRouter(
        initialLocation: '/home',
        refreshListenable: auth,
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const Text('login')),
          GoRoute(
            path: '/home',
            redirect: (_, state) =>
                AgGuard.check([AgAuthGuard(auth, loginPath: '/login')], state.fullPath!),
            builder: (_, _) => const Text('home'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.text('login'), findsOneWidget);
    });
  });
}
