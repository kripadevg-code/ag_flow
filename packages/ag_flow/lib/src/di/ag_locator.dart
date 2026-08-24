import 'package:ag_flow/src/di/ag_initializable.dart';
import 'package:flutter/foundation.dart';

/// A minimal, dependency-free service locator — AG's own replacement for
/// GetX's `Get.put`/`Get.lazyPut`/`Get.find`/`Get.delete`.
///
/// AG only ever needs three things from a DI container: register an
/// eagerly-created singleton ([put]), register a lazily-created one
/// ([lazyPut]), and resolve it later by type ([find]). No tags, no
/// scoping, no `fenix` — this framework has never needed them, and
/// adding them speculatively would just be surface area nobody exercises.
class AgLocator {
  AgLocator._();

  static final Map<Type, Object> _instances = {};
  static final Map<Type, Object Function()> _factories = {};
  static final Set<Type> _permanent = {};

  /// Registers [instance] as the singleton for [T], created eagerly.
  static void put<T extends Object>(T instance, {bool permanent = false}) {
    _instances[T] = instance;
    _factories.remove(T);
    if (permanent) _permanent.add(T);
    if (instance is AgInitializable) instance.onAgInit();
  }

  /// Registers [factory] to create [T]'s singleton the first time it's
  /// resolved via [find] — never before.
  static void lazyPut<T extends Object>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Resolves the singleton for [T] — realizing it from a pending
  /// [lazyPut] factory if this is the first access. Throws [StateError]
  /// if nothing was ever registered for [T].
  static T find<T extends Object>() {
    final existing = _instances[T];
    if (existing != null) return existing as T;

    final factory = _factories[T];
    if (factory == null) {
      throw StateError(
        'AgLocator: no instance or factory registered for $T. '
        'Did you forget to register it in an AgBinding?',
      );
    }
    final created = factory();
    _instances[T] = created;
    if (created is AgInitializable) created.onAgInit();
    return created as T;
  }

  /// Removes [T]'s registration entirely (both a realized instance and
  /// any still-pending factory), disposing it first if it's disposable —
  /// a no-op if [T] was registered [permanent].
  static void delete<T extends Object>() => deleteByType(T);

  /// [delete]'s non-generic equivalent, for callers that only have a
  /// [Type] value in hand (e.g. cleaning up every type an [AgBinding]
  /// registered when the route that ran it is popped).
  ///
  /// A realized instance that is a [ChangeNotifier] — which every
  /// `AgBaseController` is — has [ChangeNotifier.dispose] called before
  /// it's dropped. Without this, every popped route would leak its
  /// controller's listeners; GetX's own container did the equivalent via
  /// `onClose`, and losing it silently was the single biggest risk in
  /// replacing it.
  static void deleteByType(Type type) {
    if (_permanent.contains(type)) return;
    final instance = _instances.remove(type);
    _factories.remove(type);
    if (instance is ChangeNotifier) instance.dispose();
  }

  /// Test-only: clears every registration, including permanent ones,
  /// disposing each realized [ChangeNotifier] on the way out.
  @visibleForTesting
  static void reset() {
    for (final instance in _instances.values) {
      if (instance is ChangeNotifier) instance.dispose();
    }
    _instances.clear();
    _factories.clear();
    _permanent.clear();
  }
}
