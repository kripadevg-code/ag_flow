import 'package:ag_flow/src/di/ag_locator.dart';
import 'package:meta/meta.dart';

/// Registers a module's dependencies (Service → Repo → Controller) with
/// [AgLocator], scoped to the lifetime of the route that runs it.
///
/// Override [dependencies] to call [put]/[lazyPut]. Every registration
/// made through *this* binding (not [AgLocator] directly) is tracked and
/// automatically removed when the route that ran it is popped — see
/// `AgApp`, which calls [disposeAll] from its pop handling. This is what
/// makes a fresh push of the same route (e.g. a detail page for a
/// *different* item) always get a fresh controller instance, rather than
/// reusing a stale one whose `late final arguments` already resolved to
/// the previous item.
abstract class AgBinding {
  /// A [Set], not a list: re-registering the same type (a binding whose
  /// [dependencies] is re-run) must not queue two teardowns for it.
  final Set<Type> _registered = {};

  /// Registers [instance] as [T]'s singleton, scoped to this binding.
  @protected
  void put<T extends Object>(T instance, {bool permanent = false}) {
    AgLocator.put<T>(instance, permanent: permanent);
    if (!permanent) _registered.add(T);
  }

  /// Registers [factory] to lazily create [T]'s singleton, scoped to
  /// this binding.
  @protected
  void lazyPut<T extends Object>(T Function() factory) {
    AgLocator.lazyPut<T>(factory);
    _registered.add(T);
  }

  /// Register this module's Service/Repo/Controller here, via [put]/
  /// [lazyPut].
  void dependencies();

  /// Removes every type this binding has registered since the last call
  /// to this method. Called by `AgApp` when the route that ran
  /// [dependencies] is popped — never call this yourself.
  @internal
  void disposeAll() {
    _registered
      ..forEach(AgLocator.deleteByType)
      ..clear();
  }
}
