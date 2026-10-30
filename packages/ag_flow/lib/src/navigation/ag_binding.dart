import 'package:ag_flow/src/di/ag_locator.dart';
import 'package:meta/meta.dart';

/// Registers a module's dependencies (Service → Repo → Controller) with
/// [AgLocator], scoped to the lifetime of the route that runs it.
///
/// Override [dependencies] to call [put]/[lazyPut]. Every registration
/// made through *this* binding (not [AgLocator] directly) is tracked and
/// automatically removed once the last route using it is gone — see
/// `AgRoutePage`, whose route releases it from its own `dispose`. This is what
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

  /// How many live routes (or shells) currently depend on each binding
  /// type, and the instance whose [dependencies] actually ran.
  ///
  /// Keyed by *type*, not instance: go_router calls a route's
  /// `pageBuilder` again on every rebuild, so a route hands over a fresh
  /// `ProductsBinding()` each time — an instance key would count those as
  /// different bindings and never tear any of them down.
  static final Map<Type, int> _liveCounts = {};
  static final Map<Type, AgBinding> _active = {};

  /// Registers this binding's dependencies if no live route of the same
  /// binding type already has, and counts one more live user of them.
  ///
  /// Reference-counted because `AgLocator` is type-keyed, so one type has
  /// at most one live instance: two stacked pushes of the same route share
  /// one controller, and tearing down on the first pop would leave the one
  /// still on screen holding a disposed controller. Called by
  /// `AgRoutePage` and `AgShellScope` — never call this yourself.
  @internal
  static void acquire(AgBinding binding) {
    final type = binding.runtimeType;
    final live = _liveCounts[type] ?? 0;
    if (live == 0) {
      try {
        binding.dependencies();
      } catch (_) {
        // Undo what was registered before the failure, or it would outlive
        // every route with nothing left to release it.
        binding.disposeAll();
        rethrow;
      }
      _active[type] = binding;
    }
    _liveCounts[type] = live + 1;
  }

  /// The counterpart of [acquire]: once the last live user is gone, every
  /// type the binding registered is deleted (and a `ChangeNotifier`
  /// disposed).
  @internal
  static void release(AgBinding binding) {
    final type = binding.runtimeType;
    final remaining = (_liveCounts[type] ?? 1) - 1;
    if (remaining > 0) {
      _liveCounts[type] = remaining;
      return;
    }
    _liveCounts.remove(type);
    _active.remove(type)?.disposeAll();
  }

  /// Forgets every live count without tearing anything down — for tests
  /// that reset `AgLocator` between cases.
  @visibleForTesting
  static void resetLiveBindings() {
    _liveCounts.clear();
    _active.clear();
  }

  /// Removes every type this binding has registered since the last call
  /// to this method. Called once the last route using this binding is
  /// gone — never call this yourself.
  @internal
  void disposeAll() {
    _registered
      ..forEach(AgLocator.deleteByType)
      ..clear();
  }
}
