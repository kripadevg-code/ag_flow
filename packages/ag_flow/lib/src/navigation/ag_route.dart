import 'package:ag_flow/src/navigation/ag_binding.dart';
import 'package:ag_flow/src/navigation/ag_transition.dart';
import 'package:flutter/widgets.dart';

/// A single named route — AG's own replacement for GetX's `GetPage`.
///
/// Deliberately narrow: AG has only ever used a route's name, page
/// builder, binding, and transition — no deep linking, no nested
/// navigators, no per-route transition curves. Add fields here only once
/// a real, exercised need shows up.
class AgRoute {
  const AgRoute({
    required this.name,
    required this.page,
    this.binding,
    this.transition = AgTransition.rightToLeft,
  });

  /// The route path, e.g. `/product`.
  final String name;

  /// Builds this route's page widget.
  final Widget Function() page;

  /// Registers this module's dependencies each time this route is
  /// pushed, and unregisters them when it's popped. Null if the route
  /// needs none — rare; every generated module has one.
  final AgBinding? binding;

  /// The push/pop transition animation.
  final AgTransition transition;
}
