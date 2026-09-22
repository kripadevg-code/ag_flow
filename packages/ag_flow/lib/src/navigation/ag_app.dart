import 'package:ag_flow/src/navigation/ag_binding.dart';
import 'package:ag_flow/src/navigation/ag_navigator.dart';
import 'package:ag_flow/src/navigation/ag_route.dart';
import 'package:ag_flow/src/navigation/ag_transition.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The application root.
///
/// Builds a [GoRouter] from [routes] and hands it to [MaterialApp.router],
/// so an AG app gets real URLs, deep links, browser history on the web,
/// and correct system back-button behaviour without any of that being
/// AG's own code to maintain.
///
/// **Binding lifecycle.** A route's [AgBinding.dependencies] runs when its
/// first live instance is created, and its registrations are torn down —
/// controllers disposed — once its *last* live instance is gone. Two
/// edges worth knowing about:
///
/// - Registrations live in `AgLocator`, which is keyed by type, so one
///   type has at most one live instance. Pushing the same route twice (a
///   detail screen stacked on itself) shares one controller rather than
///   creating a second, so teardown is reference-counted and never fires
///   while another live instance still needs it.
/// - Teardown runs from the route's own `dispose`, not from a
///   [NavigatorObserver]. An observer's `didPop` fires when the pop
///   *begins* — the outgoing page is still mounted and still reading its
///   controller for the whole exit transition, so disposing there tears
///   a controller out from under a live widget.
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
    this.errorBuilder,
    this.redirect,
  });

  /// The location shown when the app starts, e.g. `/product`.
  final String initialRoute;

  /// Every route this app can navigate to.
  final List<AgRouteBase> routes;

  /// Registered once, before the first frame — for app-wide singletons
  /// (e.g. the shared `ApiProvider`), never a per-module dependency.
  /// Never torn down; the app owns these for its whole lifetime.
  final AgBinding? initialBinding;

  final String title;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;

  /// Shown when a location matches no route — a mistyped deep link, or a
  /// URL from an older version of the app.
  final Widget Function(BuildContext context, String location)? errorBuilder;

  /// An app-wide guard, run before every route's own [AgRoute.guards].
  /// Return a path to redirect there, or null to allow.
  final String? Function(String location)? redirect;

  @override
  State<AgApp> createState() => _AgAppState();
}

class _AgAppState extends State<AgApp> {
  /// How many live route instances currently depend on each binding.
  final Map<AgBinding, int> _liveInstances = {};

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    widget.initialBinding?.dependencies();
    _router = GoRouter(
      navigatorKey: AgNavigator.navigatorKey,
      initialLocation: widget.initialRoute,
      routes: widget.routes.map(_buildRoute).toList(),
      redirect: _appRedirect,
      errorBuilder: (context, state) =>
          widget.errorBuilder?.call(context, state.uri.toString()) ??
          _AgRouteNotFound(location: state.uri.toString()),
    );
    AgNavigator.registerRouter(_router);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  String? _appRedirect(BuildContext context, GoRouterState state) =>
      widget.redirect?.call(state.matchedLocation);

  RouteBase _buildRoute(AgRouteBase route) {
    switch (route) {
      case AgRoute():
        return _buildGoRoute(route);
      case AgShellRoute():
        final binding = route.binding;
        return ShellRoute(
          builder: (context, state, child) => route.builder(
            context,
            binding == null
                ? child
                : _AgShellScope(
                    onEnter: () => _acquireBinding(binding),
                    onLeave: () => _releaseBinding(binding),
                    child: child,
                  ),
          ),
          routes: route.routes.map(_buildGoRoute).toList(),
        );
    }
  }

  GoRoute _buildGoRoute(AgRoute route) {
    return GoRoute(
      path: route.path,
      // The path doubles as the route's name, so `AppRoutes.product` is
      // the single identifier a call site ever needs — the one constant
      // the generator writes, navigates by, and validates.
      name: route.path,
      redirect: route.guards.isEmpty
          ? null
          : (context, state) => _runGuards(route, state),
      pageBuilder: (context, state) {
        // Recorded before the page's route is created, because an eager
        // `put` in a binding constructs its controller during
        // `createRoute` — and a detail controller reads these to build
        // its typed argument.
        AgNavigator.pathParameters = state.pathParameters;
        AgNavigator.extra = state.extra;
        final binding = route.binding;
        return _AgPage<dynamic>(
          key: state.pageKey,
          child: route.page(),
          transition: route.transition,
          onCreate: binding == null ? null : () => _acquireBinding(binding),
          onDispose: binding == null ? null : () => _releaseBinding(binding),
        );
      },
    );
  }

  String? _runGuards(AgRoute route, GoRouterState state) {
    final path = state.fullPath ?? state.matchedLocation;
    for (final guard in route.guards) {
      final redirectTo = guard.redirect(path);
      if (redirectTo != null) return redirectTo;
    }
    return null;
  }

  void _acquireBinding(AgBinding binding) {
    final live = _liveInstances[binding] ?? 0;
    // Only the first live instance registers; subsequent stacked
    // instances share what's already there (AgLocator is type-keyed).
    if (live == 0) binding.dependencies();
    _liveInstances[binding] = live + 1;
  }

  void _releaseBinding(AgBinding binding) {
    final remaining = (_liveInstances[binding] ?? 1) - 1;
    if (remaining > 0) {
      _liveInstances[binding] = remaining;
      return;
    }
    _liveInstances.remove(binding);
    binding.disposeAll();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: widget.title,
      theme: widget.theme,
      darkTheme: widget.darkTheme,
      themeMode: widget.themeMode ?? ThemeMode.system,
      routerConfig: _router,
    );
  }
}

/// Ties a shell's binding to the lifetime of the shell itself, rather
/// than to any one route inside it.
class _AgShellScope extends StatefulWidget {
  const _AgShellScope({
    required this.onEnter,
    required this.onLeave,
    required this.child,
  });

  final VoidCallback onEnter;
  final VoidCallback onLeave;
  final Widget child;

  @override
  State<_AgShellScope> createState() => _AgShellScopeState();
}

class _AgShellScopeState extends State<_AgShellScope> {
  @override
  void initState() {
    super.initState();
    widget.onEnter();
  }

  @override
  void dispose() {
    widget.onLeave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The [Page] every AG route produces.
///
/// Carries the binding lifecycle hooks: [onCreate] fires as the route is
/// created (before the page is built, so a controller is registered by
/// the time the page asks for it), and [onDispose] once the route is
/// genuinely gone — after any exit transition has finished, so nothing
/// is still reading a controller that is about to be disposed.
class _AgPage<T> extends Page<T> {
  const _AgPage({
    required this.child,
    required this.transition,
    required super.key,
    this.onCreate,
    this.onDispose,
  });

  final Widget child;
  final AgTransition transition;
  final VoidCallback? onCreate;
  final VoidCallback? onDispose;

  @override
  Route<T> createRoute(BuildContext context) {
    onCreate?.call();
    return _AgPageRoute<T>(
      settings: this,
      child: child,
      transition: transition,
      onDispose: onDispose,
    );
  }
}

class _AgPageRoute<T> extends PageRouteBuilder<T> {
  _AgPageRoute({
    required super.settings,
    required Widget child,
    required AgTransition transition,
    this.onDispose,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionsBuilder: _transitionBuilderFor(transition),
         transitionDuration: transition == AgTransition.none
             ? Duration.zero
             : const Duration(milliseconds: 300),
         reverseTransitionDuration: transition == AgTransition.none
             ? Duration.zero
             : const Duration(milliseconds: 300),
       );

  final VoidCallback? onDispose;

  @override
  void dispose() {
    onDispose?.call();
    super.dispose();
  }

  static RouteTransitionsBuilder _transitionBuilderFor(
    AgTransition transition,
  ) {
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

/// Default destination for a location that matches no route.
class _AgRouteNotFound extends StatelessWidget {
  const _AgRouteNotFound({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 48),
              const SizedBox(height: 12),
              Text(
                'No route matches "$location".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
