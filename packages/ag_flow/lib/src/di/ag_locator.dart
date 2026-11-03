import 'package:ag_flow/src/di/ag_initializable.dart';
import 'package:flutter/foundation.dart';

/// A minimal, dependency-free service locator.
///
/// AG only ever needs three things from a DI container: register an
/// eagerly-created singleton ([put]), register a lazily-created one
/// ([lazyPut]), and resolve it later by type ([find]). No tags and no
/// `fenix` — this framework has never needed them.
///
/// **Route scopes.** What an `AgBinding` registers while its route is
/// pushed lives in that route's own [AgScope], not in the global registry,
/// so `/product/7` and `/product/9` on the stack at once each get their own
/// Service, Repo and Controller. A page resolves its route's scope
/// directly; any other [find] looks in the global registry, then in the
/// live route scopes, most recent first.
class AgLocator {
  AgLocator._();

  static final Map<Type, Object> _instances = {};
  static final Map<Type, Object Function()> _factories = {};
  static final Set<Type> _permanent = {};

  /// Live route scopes, oldest first.
  static final List<AgScope> _live = [];

  /// Where [put]/[lazyPut] register while a binding runs; `null` is global.
  static AgScope? _target;

  /// The scope a [find] resolves in first, while one of its factories runs.
  static AgScope? _resolving;

  static final Expando<List<AgScope>> _owners = Expando('AgLocator owners');

  /// Registers [instance] as the singleton for [T], created eagerly.
  ///
  /// Registering over an existing instance disposes the one being
  /// replaced — it is unreachable through this locator the moment the
  /// line below runs, so anything still listening to it would leak for
  /// the rest of the app's lifetime otherwise. A [permanent] instance is
  /// always global, even when a route's binding registers it.
  static void put<T extends Object>(T instance, {bool permanent = false}) {
    final scope = permanent ? null : _target;
    final instances = scope?._instances ?? _instances;
    final replaced = instances[T];
    if (replaced is ChangeNotifier && !identical(replaced, instance)) {
      replaced.dispose();
    }
    instances[T] = instance;
    (scope?._factories ?? _factories).remove(T);
    if (permanent) _permanent.add(T);
    if (instance is AgInitializable) instance.onAgInit();
  }

  /// Registers [factory] to create [T]'s singleton the first time it's
  /// resolved via [find] — never before.
  static void lazyPut<T extends Object>(T Function() factory) {
    (_target?._factories ?? _factories)[T] = factory;
  }

  /// Resolves the singleton for [T] — realizing it from a pending
  /// [lazyPut] factory if this is the first access. Throws [StateError]
  /// if nothing was ever registered for [T].
  ///
  /// Inside a route scope's factory, that scope is searched first. A
  /// registered instance always wins over a factory, so a test fake [put]
  /// globally replaces what a route's binding would build.
  static T find<T extends Object>() => _resolve(T, _resolving) as T;

  /// [find], starting from the route scope [owner] was attached to — how
  /// a page finds its own route's controller.
  @internal
  static T findFor<T extends Object>(Object owner) {
    final scopes = _owners[owner];
    return _resolve(T, scopes == null || scopes.isEmpty ? _resolving : scopes.last) as T;
  }

  static Object _resolve(Type type, AgScope? scope) {
    final local = scope?._instances[type];
    if (local != null) return local;
    final global = _instances[type];
    if (global != null) return global;
    if (scope != null && scope._factories.containsKey(type)) {
      return scope._create(type);
    }
    for (final live in _live.reversed) {
      if (identical(live, scope)) continue;
      final instance = live._instances[type];
      if (instance != null) return instance;
      if (live._factories.containsKey(type)) return live._create(type);
    }
    final factory = _factories[type];
    if (factory == null) {
      throw StateError(
        'AgLocator: no instance or factory registered for $type. '
        'Did you forget to register it in an AgBinding?',
      );
    }
    final previous = _resolving;
    _resolving = null;
    try {
      final created = factory();
      _instances[type] = created;
      if (created is AgInitializable) created.onAgInit();
      return created;
    } finally {
      _resolving = previous;
    }
  }

  /// Opens a route scope and runs [register] with every [put]/[lazyPut]
  /// directed into it. [onCreate] runs before the scope builds an
  /// instance, so a lazily-built controller sees its own route's data.
  @internal
  static AgScope openScope(void Function() register, {VoidCallback? onCreate}) {
    final scope = AgScope._(onCreate);
    _live.add(scope);
    final previous = _target;
    _target = scope;
    try {
      register();
    } catch (_) {
      scope.dispose();
      rethrow;
    } finally {
      _target = previous;
    }
    return scope;
  }

  /// Makes [owner] — a route's page widget — resolve in [scope].
  ///
  /// A `const` page is one shared object, so attaching it to a second live
  /// scope would make both routes read the same controller: that is
  /// reported, and the newest route wins.
  @internal
  static void attach(Object owner, AgScope scope) {
    final scopes = _owners[owner] ??= [];
    if (scopes.isNotEmpty) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: StateError(
            'AgLocator: ${owner.runtimeType} is shown by two routes at once '
            'as one shared (const) object, so both would use one controller. '
            'Build it per route: `child: ${owner.runtimeType}(key: state.pageKey)`.',
          ),
          library: 'ag_flow',
        ),
      );
    }
    scopes.add(scope);
    scope._owners.add(owner);
  }

  /// Removes [T]'s global registration entirely (both a realized instance
  /// and any still-pending factory), disposing it first if it's
  /// disposable — a no-op if [T] was registered [permanent]. A route
  /// scope's registrations are released with its route.
  static void delete<T extends Object>() => deleteByType(T);

  /// [delete]'s non-generic equivalent, for callers that only have a
  /// [Type] value in hand.
  ///
  /// A realized instance that is a [ChangeNotifier] — which every
  /// `AgBaseController` is — has [ChangeNotifier.dispose] called before
  /// it's dropped, or its listeners would leak.
  static void deleteByType(Type type) {
    if (_permanent.contains(type)) return;
    final instance = _instances.remove(type);
    _factories.remove(type);
    if (instance is ChangeNotifier) instance.dispose();
  }

  /// Test-only: clears every registration, including permanent ones and
  /// live route scopes, disposing each realized [ChangeNotifier].
  @visibleForTesting
  static void reset() {
    for (final scope in [..._live]) {
      scope.dispose();
    }
    for (final instance in _instances.values) {
      if (instance is ChangeNotifier) instance.dispose();
    }
    _instances.clear();
    _factories.clear();
    _permanent.clear();
    _target = null;
    _resolving = null;
  }
}

/// One route's (or shell's) registrations, opened by [AgLocator.openScope]
/// and disposed with the route.
@internal
final class AgScope {
  AgScope._(this._onCreate);

  final VoidCallback? _onCreate;
  final Map<Type, Object> _instances = {};
  final Map<Type, Object Function()> _factories = {};
  final List<Object> _owners = [];

  Object _create(Type type) {
    final factory = _factories[type]!;
    final previous = AgLocator._resolving;
    AgLocator._resolving = this;
    try {
      _onCreate?.call();
      final created = factory();
      _instances[type] = created;
      if (created is AgInitializable) created.onAgInit();
      return created;
    } finally {
      AgLocator._resolving = previous;
    }
  }

  /// Disposes every realized [ChangeNotifier] and drops the scope.
  void dispose() {
    if (!AgLocator._live.remove(this)) return;
    for (final owner in _owners) {
      AgLocator._owners[owner]?.remove(this);
    }
    for (final instance in _instances.values) {
      if (instance is ChangeNotifier) instance.dispose();
    }
    _instances.clear();
    _factories.clear();
  }
}
