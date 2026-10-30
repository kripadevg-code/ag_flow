import 'package:ag_flow/src/navigation/ag_binding.dart';
import 'package:ag_flow/src/navigation/ag_route_data.dart';
import 'package:ag_flow/src/navigation/ag_transition.dart';
import 'package:flutter/material.dart';

/// The [Page] an AG module's route builds — the one piece of AG that sits
/// inside the app's own router.
///
/// AG does not own routing: the app owns its go_router `GoRouter` (the CLI
/// generates it in `core/routes/app_pages.dart`) and can upgrade go_router
/// on its own schedule. All this page adds is the module lifecycle:
///
/// ```dart
/// GoRoute(
///   path: AppRoutes.product,
///   name: AppRoutes.product,
///   pageBuilder: (context, state) => AgRoutePage(
///     key: state.pageKey,
///     pathParameters: state.pathParameters,
///     extra: state.extra,
///     binding: ProductsBinding(),
///     child: const ProductsPage(),
///   ),
/// )
/// ```
///
/// - [binding] registers as the route is created — before the page is
///   built, so its controller is there when the page asks for it — and is
///   released from the route's own `dispose`, once the route is genuinely
///   gone. Never from a `NavigatorObserver`: an observer's `didPop` fires
///   when the pop *begins*, while the outgoing page is still on screen and
///   still reading its controller for the whole exit transition.
/// - Release is reference-counted per binding type (see
///   [AgBinding.acquire]), so two stacked instances of one route share one
///   controller and only the last pop tears it down.
/// - [pathParameters] and [extra] are recorded in `AgRouteData`, which a
///   detail controller reads in its constructor.
///
/// Leave a page with go_router's `pushReplacement`, never `replace`:
/// `replace` reuses the outgoing page's key, so Flutter *updates* the old
/// route instead of creating a new one — the new binding never registers
/// and the old one is never released.
class AgRoutePage<T> extends Page<T> {
  const AgRoutePage({
    required this.child,
    super.key,
    super.name,
    this.binding,
    this.transition = AgTransition.rightToLeft,
    this.pathParameters = const {},
    this.extra,
  });

  /// The module's page widget.
  final Widget child;

  /// The module's binding — its Service, Repo and Controller.
  final AgBinding? binding;

  final AgTransition transition;

  /// The route's resolved path parameters (go_router: `state.pathParameters`).
  final Map<String, String> pathParameters;

  /// The route's non-URL payload (go_router: `state.extra`).
  final Object? extra;

  @override
  Route<T> createRoute(BuildContext context) {
    // Recorded before the binding runs: an eager `put` constructs its
    // controller right here, and a detail controller reads these as it is
    // constructed.
    _record();
    final binding = this.binding;
    if (binding != null) AgBinding.acquire(binding);
    return _AgPageRoute<T>(
      settings: this,
      // Recorded again as the page builds: a `lazyPut` controller is only
      // constructed then, and on a deep link several routes are created
      // before any of them builds.
      child: _AgRouteDataScope(onBuild: _record, child: child),
      transition: transition,
      onDispose: binding == null ? null : () => AgBinding.release(binding),
    );
  }

  void _record() {
    AgRouteData.pathParameters = pathParameters;
    AgRouteData.extra = extra;
  }
}

/// Ties a binding to a widget's lifetime rather than a route's — for
/// persistent chrome (a bottom bar, a rail) wrapping a go_router
/// `ShellRoute`, whose controller must survive navigation between the
/// routes inside it.
///
/// ```dart
/// ShellRoute(
///   builder: (context, state, child) => AgShellScope(
///     binding: ShellBinding(),
///     child: ShellPage(child: child),
///   ),
///   routes: [...],
/// )
/// ```
class AgShellScope extends StatefulWidget {
  const AgShellScope({required this.binding, required this.child, super.key});

  final AgBinding binding;
  final Widget child;

  @override
  State<AgShellScope> createState() => _AgShellScopeState();
}

class _AgShellScopeState extends State<AgShellScope> {
  // The binding that was acquired, not whatever a rebuild passes later —
  // the builder hands over a fresh instance each time.
  late final AgBinding _binding = widget.binding;

  @override
  void initState() {
    super.initState();
    AgBinding.acquire(_binding);
  }

  @override
  void dispose() {
    AgBinding.release(_binding);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AgRouteDataScope extends StatelessWidget {
  const _AgRouteDataScope({required this.onBuild, required this.child});

  final VoidCallback onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
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
