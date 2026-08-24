import 'package:ag_flow/src/navigation/ag_binding.dart';
import 'package:ag_flow/src/navigation/ag_navigator.dart';
import 'package:ag_flow/src/navigation/ag_route.dart';
import 'package:ag_flow/src/navigation/ag_transition.dart';
import 'package:flutter/material.dart';

/// The application root — AG's own replacement for GetX's
/// `GetMaterialApp`.
///
/// Wraps [MaterialApp], wiring [routes] (built from [AgRoute]s),
/// [initialRoute], and [initialBinding] (registered once, before the
/// first frame).
///
/// **Binding lifecycle.** A route's [AgBinding.dependencies] runs when
/// its first live instance is pushed, and its registrations are torn
/// down — controllers disposed — once its *last* live instance leaves
/// the stack, by any route: popped, replaced, or removed. The two edges
/// worth knowing about:
///
/// - Registrations live in [AgLocator], which is keyed by type, so one
///   type has at most one live instance. Pushing the same route twice
///   (a detail screen stacked on itself) therefore shares one controller
///   rather than creating a second — so teardown is reference-counted,
///   never fired while another live instance still needs it.
/// - `Navigator` reports removal three different ways. Only handling
///   `didPop` would silently leak every route left via
///   [AgNavigator.offNamed]/[AgNavigator.offAllNamed], which never pop.
class AgApp extends StatefulWidget {
  const AgApp({
    required this.initialRoute,
    required this.routes,
    super.key,
    this.initialBinding,
    this.title = '',
    this.theme,
    this.darkTheme,
    this.themeMode,
  });

  /// The first route pushed when the app starts.
  final String initialRoute;

  /// Every route this app can navigate to.
  final List<AgRoute> routes;

  /// Registered once, before the first frame — for app-wide singletons
  /// (e.g. the shared `ApiProvider`), never a per-module dependency.
  /// Never torn down; the app owns these for its whole lifetime.
  final AgBinding? initialBinding;

  final String title;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;

  @override
  State<AgApp> createState() => _AgAppState();
}

class _AgAppState extends State<AgApp> {
  /// Routes by name — a map rather than a scan of [AgApp.routes], so
  /// resolving a push stays O(1) as an app grows past a handful of
  /// screens.
  late Map<String, AgRoute> _routesByName;

  /// Which binding each live route instance was opened with. Keyed by the
  /// [Route] itself, not its name: two stacked instances of one route are
  /// distinct keys, where names would collide.
  final Map<Route<dynamic>, AgBinding> _bindingForRoute = {};

  /// How many live route instances currently depend on each binding.
  final Map<AgBinding, int> _liveInstances = {};

  late final AgNavigatorObserver _argumentsObserver;
  late final _BindingLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _routesByName = _indexRoutes(widget.routes);
    widget.initialBinding?.dependencies();
    _argumentsObserver = AgNavigatorObserver();
    _lifecycleObserver = _BindingLifecycleObserver(_releaseBindingFor);
  }

  @override
  void didUpdateWidget(AgApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.routes, widget.routes)) {
      _routesByName = _indexRoutes(widget.routes);
    }
  }

  static Map<String, AgRoute> _indexRoutes(List<AgRoute> routes) {
    final byName = <String, AgRoute>{};
    for (final route in routes) {
      assert(
        !byName.containsKey(route.name),
        'AgApp: duplicate route name "${route.name}". Every AgRoute in '
        '`routes` must have a unique name — two entries sharing one name '
        'means the second is unreachable.',
      );
      byName[route.name] = route;
    }
    return byName;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: widget.theme,
      darkTheme: widget.darkTheme,
      themeMode: widget.themeMode ?? ThemeMode.system,
      navigatorKey: AgNavigator.navigatorKey,
      navigatorObservers: [_argumentsObserver, _lifecycleObserver],
      initialRoute: widget.initialRoute,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final matched = _routesByName[settings.name];
    if (matched == null) return null;

    final route = PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => matched.page(),
      transitionsBuilder: _transitionBuilderFor(matched.transition),
    );

    final binding = matched.binding;
    if (binding != null) {
      final live = _liveInstances[binding] ?? 0;
      // Only the first live instance registers; subsequent stacked
      // instances share what's already there (AgLocator is type-keyed).
      if (live == 0) binding.dependencies();
      _liveInstances[binding] = live + 1;
      _bindingForRoute[route] = binding;
    }

    return route;
  }

  void _releaseBindingFor(Route<dynamic> route) {
    final binding = _bindingForRoute.remove(route);
    if (binding == null) return;

    final remaining = (_liveInstances[binding] ?? 1) - 1;
    if (remaining > 0) {
      _liveInstances[binding] = remaining;
      return;
    }
    _liveInstances.remove(binding);
    binding.disposeAll();
  }

  RouteTransitionsBuilder _transitionBuilderFor(AgTransition transition) {
    switch (transition) {
      case AgTransition.rightToLeft:
        return (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
              child: child,
            );
      case AgTransition.fade:
        return (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child);
      case AgTransition.none:
        return (context, animation, secondaryAnimation, child) => child;
    }
  }
}

/// Releases a route's `AgBinding` registrations once it leaves the stack.
///
/// Kept separate from [AgNavigatorObserver] — that one is public, small,
/// and only ever concerns [AgNavigator.arguments]; binding lifecycle is
/// `AgApp`-internal bookkeeping.
class _BindingLifecycleObserver extends NavigatorObserver {
  _BindingLifecycleObserver(this._release);

  final void Function(Route<dynamic> route) _release;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _release(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _release(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _release(oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
