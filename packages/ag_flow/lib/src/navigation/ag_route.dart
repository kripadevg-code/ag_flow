import 'package:ag_flow/src/navigation/ag_binding.dart';
import 'package:ag_flow/src/navigation/ag_guard.dart';
import 'package:ag_flow/src/navigation/ag_transition.dart';
import 'package:flutter/widgets.dart';

/// Common supertype for the entries in `AgApp.routes`.
///
/// Sealed so `AgApp` can switch exhaustively over the two kinds — a
/// plain [AgRoute] and an [AgShellRoute] — and a third kind can't be
/// added from outside the framework without the compiler pointing at
/// every place that has to handle it.
sealed class AgRouteBase {
  const AgRouteBase();
}

/// A single navigable route.
///
/// [path] is both the URL this route answers on *and* its identity: it
/// is what `AppRoutes` holds, what [AgNavigator] is given, and what the
/// generator writes into `app_pages.dart`. Keeping it as one value
/// rather than a separate name/path pair is deliberate — every module
/// then has exactly one route constant, the way it always has.
///
/// A path may declare parameters with a leading colon:
///
/// ```dart
/// AgRoute(
///   path: '/product/:id',
///   page: ProductDetailsPage.new,
///   binding: ProductDetailsBinding(),
/// )
/// ```
///
/// which makes the route deep-linkable (`myapp://product/42`, or
/// `/product/42` on the web) and is read back through
/// `AgDetailController.arguments`.
class AgRoute extends AgRouteBase {
  const AgRoute({
    required this.path,
    required this.page,
    this.binding,
    this.transition = AgTransition.rightToLeft,
    this.guards = const [],
  });

  /// The URL path template, e.g. `/product` or `/product/:id`.
  final String path;

  /// Builds this route's page widget.
  final Widget Function() page;

  /// Registers this module's dependencies when this route is pushed, and
  /// unregisters them once it is gone. Null if the route needs none —
  /// rare; every generated module has one.
  final AgBinding? binding;

  /// The push/pop transition animation.
  final AgTransition transition;

  /// Zero or more guards that run **in order** before this route is
  /// built. The first guard returning a non-null path redirects there
  /// and the rest are skipped. An empty list means "always allow".
  final List<AgGuard> guards;
}

/// Wraps a group of routes in shared, persistent chrome — a bottom
/// navigation bar, a side rail, a tabbed scaffold.
///
/// The [builder]'s `child` is whichever of [routes] is currently active.
/// The chrome itself is built once and *stays* built as the user moves
/// between those routes, so its own state (a scroll offset, an
/// animation, a selected tab) survives navigation.
///
/// ```dart
/// AgShellRoute(
///   builder: (context, child) => AppScaffold(child: child),
///   routes: [
///     AgRoute(path: '/home', page: HomePage.new, binding: HomeBinding()),
///     AgRoute(path: '/cart', page: CartPage.new, binding: CartBinding()),
///   ],
/// )
/// ```
class AgShellRoute extends AgRouteBase {
  const AgShellRoute({
    required this.builder,
    required this.routes,
    this.binding,
  });

  /// Builds the persistent chrome around the active route's page.
  final Widget Function(BuildContext context, Widget child) builder;

  /// The routes rendered inside this shell.
  final List<AgRoute> routes;

  /// Registered when the shell is first entered and released when it is
  /// left — for dependencies the whole shell shares (e.g. the controller
  /// backing a bottom navigation bar).
  final AgBinding? binding;
}
