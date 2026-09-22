import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';

/// Context-less navigation, and the current route's parameters.
///
/// Works from anywhere — a Controller, a guard, a plain object, no
/// [BuildContext] needed — through the [GoRouter] that `AgApp` builds
/// and registers here. Navigation is by the same path constant
/// `AppRoutes` holds and `app_pages.dart` registers, so a call site
/// names a route exactly once.
class AgNavigator {
  AgNavigator._();

  /// The navigator `AgApp` hands to [GoRouter]. Exposed so a consuming
  /// app's own tests can reach it.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static GoRouter? _router;

  /// The path parameters of the route currently being entered, e.g.
  /// `{'id': '42'}` for `/product/:id` opened at `/product/42`.
  /// `AgDetailController` reads this to build its typed argument.
  static Map<String, String> pathParameters = const {};

  /// The non-URL payload passed to the current navigation, if any.
  ///
  /// Convenient for handing a whole object to the next page, but it is
  /// *not* deep-link safe: open the same URL cold (from a link, a
  /// notification, a browser reload) and there is no extra to read.
  /// Anything a page genuinely needs belongs in the path.
  static Object? extra;

  /// Registered by `AgApp`; never call this yourself. Also clears the
  /// previous app's route parameters — a new router means a new routing
  /// context, and leaving the old one readable would let a controller
  /// built early in the new app resolve a stale argument.
  @internal
  static void registerRouter(GoRouter router) {
    _router = router;
    pathParameters = const {};
    extra = null;
  }

  static GoRouter get _current {
    final router = _router;
    if (router == null) {
      throw StateError(
        'AgNavigator: no AgApp is currently mounted — navigation only '
        'works once one is.',
      );
    }
    return router;
  }

  /// Pushes [path] on top of the current route.
  ///
  /// This is a stack push: [back] returns to where the user was. On the
  /// web the address bar is deliberately left alone — that is go_router's
  /// own semantics for an imperative push. Use [offAllNamed] when the
  /// destination should become the app's location (and so a shareable
  /// URL) rather than a layer on top of it.
  ///
  /// [pathParameters] fills in the `:token`s the route declares;
  /// [queryParameters] appends a query string; [extra] passes a non-URL
  /// payload (see [AgNavigator.extra] for why to prefer the path).
  static Future<T?> toNamed<T extends Object?>(
    String path, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    return _current.pushNamed<T>(
      path,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Replaces the current route with [path].
  ///
  /// Uses `pushReplacement`, never go_router's `replace`: `replace`
  /// reuses the outgoing page's key, so Flutter *updates* the existing
  /// route instead of creating a new one — the new page's binding would
  /// never be registered, the old one never released, and the route
  /// would keep rendering the previous page's content.
  static Future<T?> offNamed<T extends Object?>(
    String path, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    return _current.pushReplacementNamed<T>(
      path,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Clears the stack down to [path] and shows it — what a sign-out or a
  /// sign-in completing should use.
  static void offAllNamed(
    String path, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    _current.goNamed(
      path,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Navigates to a raw location string, e.g. `/product/42`.
  ///
  /// For links that arrive from outside the app — a push notification
  /// payload, a QR code, a custom URL scheme — where what you hold is a
  /// URL, not a route constant plus parameters. An unmatched location
  /// lands on `AgApp.errorBuilder` rather than throwing.
  static void toLocation(String location, {Object? extra}) =>
      _current.go(location, extra: extra);

  /// Pops the current route, if anything is left to pop.
  static void back<T extends Object?>([T? result]) {
    final router = _current;
    if (router.canPop()) router.pop<T>(result);
  }

  /// Whether there is a route below the current one to pop back to.
  static bool get canPop => _current.canPop();

  /// The location currently displayed, e.g. `/product/42`.
  static String get location =>
      _current.routerDelegate.currentConfiguration.uri.toString();

  /// Test-only: clears the registered router and current route
  /// parameters between tests.
  @visibleForTesting
  static void reset() {
    _router = null;
    pathParameters = const {};
    extra = null;
  }
}
