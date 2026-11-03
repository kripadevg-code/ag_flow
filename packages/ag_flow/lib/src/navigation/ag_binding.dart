import 'package:ag_flow/src/di/ag_locator.dart';
import 'package:flutter/foundation.dart';

/// Registers a module's dependencies (Service → Repo → Controller) with
/// [AgLocator], scoped to the lifetime of the route that runs it.
///
/// Override [dependencies] to call [put]/[lazyPut]. Each push of a route
/// runs its binding into a scope of its own — see `AgRoutePage`, whose
/// route releases it from its own `dispose` — so two live instances of one
/// route (a detail page for item 7 under one for item 9) never share a
/// controller, and popping one disposes only its own.
abstract class AgBinding {
  /// Registers [instance] as [T]'s singleton, scoped to this binding's
  /// route ([permanent] registers it globally instead).
  @protected
  void put<T extends Object>(T instance, {bool permanent = false}) =>
      AgLocator.put<T>(instance, permanent: permanent);

  /// Registers [factory] to lazily create [T]'s singleton, scoped to
  /// this binding's route.
  @protected
  void lazyPut<T extends Object>(T Function() factory) => AgLocator.lazyPut<T>(factory);

  /// Register this module's Service/Repo/Controller here, via [put]/
  /// [lazyPut].
  void dependencies();

  /// Runs [binding]'s [dependencies] into a new route scope. If it throws,
  /// whatever it registered first is disposed. Called by `AgRoutePage` and
  /// `AgShellScope` — never call this yourself.
  @internal
  static AgScope acquire(AgBinding binding, {VoidCallback? onCreate}) =>
      AgLocator.openScope(binding.dependencies, onCreate: onCreate);

  /// The counterpart of [acquire]: disposes the scope's instances.
  @internal
  static void release(AgScope scope) => scope.dispose();
}
