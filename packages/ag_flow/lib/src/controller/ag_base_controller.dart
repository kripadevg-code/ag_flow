import 'dart:async';

import 'package:ag_flow/src/di/ag_initializable.dart';
import 'package:ag_flow/src/page/ag_page_state.dart';
import 'package:flutter/foundation.dart';

/// Base class for every AG controller.
///
/// Owns page-level state — [loadInitial], [refresh], [retry], and the
/// current [state] as an [AgPageState]. Subclasses implement [fetch] to
/// load their data by calling their Repo; a controller must never call a
/// Service or `ApiProvider` directly.
///
/// Extends [ChangeNotifier] directly: [emit] calls [notifyListeners], and
/// `AgPage` listens to the controller itself for page-state rebuilds. A
/// pagination-only change (see [AgPaginationMixin]) notifies through a
/// *separate* notifier instead, so it never also re-triggers `AgPage`'s
/// loading/error/empty/success switch, and vice versa.
///
/// ---
/// ### Accessing a controller anywhere — no generics
///
/// Every concrete controller should expose a `find` static getter so it
/// can be resolved from [AgLocator] without any generic syntax:
///
/// ```dart
/// class LoginController extends AgBaseController<User> {
///   // One line — add this to every controller.
///   static LoginController get find => AgLocator.find<LoginController>();
///
///   LoginController(this._repo);
///   final LoginRepo _repo;
///   // ...
/// }
/// ```
///
/// Then anywhere in the app — a guard, a page, another controller:
///
/// ```dart
/// final loginController = LoginController.find;
/// ```
///
/// Dart infers the type from the left-hand side. No `<LoginController>`
/// needed at the call site.
abstract class AgBaseController<T> extends ChangeNotifier
    implements AgInitializable {
  AgBaseController({this.autoLoadOnInit = true});

  /// Whether [loadInitial] runs automatically once this controller is
  /// realized by `AgLocator` (see [onAgInit]).
  final bool autoLoadOnInit;

  AgPageState<T> _pageState = const AgPageState.initial();
  bool _disposed = false;
  int _requestToken = 0;

  /// The current page state.
  AgPageState<T> get state => _pageState;

  /// Whether this controller has been disposed — its route popped, and
  /// its registration torn down by `AgBinding`.
  ///
  /// An in-flight [fetch] that completes *after* that point must not
  /// touch state or notify listeners (a disposed [ChangeNotifier] throws
  /// on [notifyListeners]). Backing out of a screen while its first load
  /// is still running is completely ordinary, so this is a normal path,
  /// not an edge case — [emit] silently no-ops once disposed.
  bool get isDisposed => _disposed;

  /// The token identifying the most recently started load.
  ///
  /// Capture this before an `await` and pass it to [isCurrentRequest]
  /// afterwards to find out whether the result is still wanted. Used by
  /// [AgPaginationMixin.loadMore], which must be invalidated by a
  /// [refresh] that started while it was in flight.
  @protected
  int get currentRequestToken => _requestToken;

  /// Starts a new logical load, invalidating any still in flight.
  ///
  /// Two loads can overlap in completely ordinary use — tapping retry
  /// twice, or pulling to refresh while the first load is still
  /// running — and responses can arrive out of order. Without this, the
  /// *slower* request wins and quietly overwrites fresher data with
  /// staler data.
  @protected
  int startRequest() => ++_requestToken;

  /// Whether [token] is still the newest started load and this
  /// controller is alive. False means the result must be discarded
  /// rather than emitted.
  @protected
  bool isCurrentRequest(int token) => token == _requestToken && !_disposed;

  @override
  void onAgInit() {
    if (autoLoadOnInit) {
      unawaited(loadInitial());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Loads this controller's data. Must call the Repo — never a Service or
  /// `ApiProvider` directly. Throw to signal failure; AG turns the
  /// exception into [AgPageState.error] automatically.
  @protected
  Future<T> fetch();

  /// Whether [data] should be presented as the empty state rather than
  /// success. Default: true for an empty [Iterable], false otherwise.
  /// Override for data shapes where "empty" means something else (e.g. a
  /// nullable detail record that wasn't found).
  @protected
  bool isEmptyData(T data) => data is Iterable && data.isEmpty;

  /// Runs [fetch] and transitions through loading to success/empty/error.
  Future<void> loadInitial() async {
    emit(const AgPageState.loading());
    await _runFetch();
  }

  /// Re-runs [fetch]. If data is already loaded, it stays visible (via
  /// [AgPageState.success]'s `isRefreshing` flag) instead of being
  /// replaced by a loading indicator while the refresh is in flight.
  Future<void> refresh() async {
    final current = state;
    emit(
      current is AgPageSuccess<T>
          ? current.copyWith(isRefreshing: true)
          : const AgPageState.loading(),
    );
    await _runFetch();
  }

  /// Re-runs [loadInitial]. Exposed separately so subclasses may customize
  /// retry semantics independently of the initial load later.
  Future<void> retry() => loadInitial();

  Future<void> _runFetch() async {
    final token = startRequest();
    try {
      final data = await fetch();
      if (!isCurrentRequest(token)) return;
      emit(
        isEmptyData(data)
            ? const AgPageState.empty()
            : AgPageState.success(data),
      );
      // A developer's fetch() may throw anything (Exception, Error, a bare
      // String, ...) — AG's contract is to turn all of it into
      // AgPageState.error, so this catch is deliberately unconstrained.
      // ignore: avoid_catches_without_on_clauses
    } catch (error, stackTrace) {
      if (!isCurrentRequest(token)) return;
      emit(AgPageState.error(error, stackTrace, state.dataOrNull));
    }
  }

  /// Escape hatch for feature-specific state transitions (e.g. an
  /// optimistic update after a mutation completes).
  @protected
  // Kept as a method rather than a `state` setter so a call site reads as
  // an explicit, deliberate override rather than a plain property
  // assignment.
  void emit(AgPageState<T> next) {
    if (_disposed) return;
    _pageState = next;
    notifyListeners();
  }
}
