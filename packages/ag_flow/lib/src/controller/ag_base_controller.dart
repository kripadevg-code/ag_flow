import 'dart:async';

import 'package:ag_flow/src/page/ag_page_state.dart';
import 'package:get/get.dart';
import 'package:meta/meta.dart';

/// Base class for every AG controller.
///
/// Owns page-level state — [loadInitial], [refresh], [retry], and the
/// current [state] as an [AgPageState]. Subclasses implement [fetch] to
/// load their data by calling their Repo; a controller must never call a
/// Service or `ApiProvider` directly.
abstract class AgBaseController<T> extends GetxController {
  AgBaseController({this.autoLoadOnInit = true});

  /// Whether [loadInitial] runs automatically from [onInit].
  final bool autoLoadOnInit;

  final Rx<AgPageState<T>> _pageState = Rx<AgPageState<T>>(
    const AgPageState.initial(),
  );

  /// The current page state.
  AgPageState<T> get state => _pageState.value;

  @override
  void onInit() {
    super.onInit();
    if (autoLoadOnInit) {
      unawaited(loadInitial());
    }
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
  @override
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
    try {
      final data = await fetch();
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
      emit(AgPageState.error(error, stackTrace, state.dataOrNull));
    }
  }

  /// Escape hatch for feature-specific state transitions (e.g. an
  /// optimistic update after a mutation completes).
  @protected
  // Kept as a method rather than a `state` setter so a call site reads as
  // an explicit, deliberate override rather than a plain property
  // assignment.
  // ignore: use_setters_to_change_properties
  void emit(AgPageState<T> next) => _pageState.value = next;
}
