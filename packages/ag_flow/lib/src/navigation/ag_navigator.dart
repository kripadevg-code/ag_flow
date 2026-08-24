import 'package:flutter/widgets.dart';

/// Context-less navigation, and the most-recently-pushed route's
/// `arguments` — AG's own replacement for GetX's `Get.toNamed`/
/// `Get.back`/`Get.arguments`.
///
/// Works from anywhere — a Controller, a plain object, no [BuildContext]
/// needed — through the single [NavigatorState] `AgApp` registers itself
/// with via [navigatorKey]. This is the same technique GetX's own
/// context-less navigation uses under the hood.
class AgNavigator {
  AgNavigator._();

  /// The single navigator every `AgApp` wires itself to. Exposed so a
  /// consuming app's own tests can pump an `AgApp` and still resolve
  /// this navigator.
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// The most recently pushed (or, after a pop, revealed) route's
  /// `arguments` — kept up to date by [AgNavigatorObserver], which
  /// `AgApp` attaches automatically. `AgArguments.resolve` reads this.
  static Object? arguments;

  static NavigatorState get _navigator {
    final state = navigatorKey.currentState;
    if (state == null) {
      throw StateError(
        'AgNavigator: no AgApp is currently mounted — navigation methods '
        'only work once one is.',
      );
    }
    return state;
  }

  /// Pushes [route] by name, carrying [arguments].
  static Future<T?> toNamed<T extends Object?>(
    String route, {
    Object? arguments,
  }) {
    return _navigator.pushNamed<T>(route, arguments: arguments);
  }

  /// Replaces the current route with [route] — the [Navigator
  /// .pushReplacementNamed] equivalent of [toNamed].
  static Future<T?> offNamed<T extends Object?>(
    String route, {
    Object? arguments,
  }) {
    return _navigator.pushReplacementNamed<T, void>(
      route,
      arguments: arguments,
    );
  }

  /// Clears the entire navigation stack and pushes [route] — the
  /// [Navigator.pushNamedAndRemoveUntil] equivalent of [toNamed].
  static Future<T?> offAllNamed<T extends Object?>(
    String route, {
    Object? arguments,
  }) {
    return _navigator.pushNamedAndRemoveUntil<T>(
      route,
      (_) => false,
      arguments: arguments,
    );
  }

  /// Pops the current route.
  static void back<T extends Object?>([T? result]) => _navigator.pop<T>(result);

  /// Test-only: resets [arguments] between tests that don't go through a
  /// full [AgNavigatorObserver] push/pop cycle.
  @visibleForTesting
  static void reset() => arguments = null;
}

/// Records the most recently revealed route's `arguments` into
/// [AgNavigator.arguments] — attached to `AgApp`'s `navigatorObservers`
/// automatically. This is what makes `arguments` readable from anywhere
/// with no [BuildContext], matching GetX's own `Get.arguments` behavior.
class AgNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AgNavigator.arguments = route.settings.arguments;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AgNavigator.arguments = previousRoute?.settings.arguments;
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AgNavigator.arguments = newRoute?.settings.arguments;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
