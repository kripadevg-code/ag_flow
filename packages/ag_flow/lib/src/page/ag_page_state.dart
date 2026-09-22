import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

const _dataEquality = DeepCollectionEquality();

/// The state of a page (or a section of one) driven by an
/// `AgBaseController`.
///
/// Exactly one of [AgPageInitial], [AgPageLoading], [AgPageSuccess],
/// [AgPageEmpty], or [AgPageError] is ever the current state — illegal
/// combinations (e.g. "loading" and "has data" at once) are not
/// representable, which is what makes independently overriding each of
/// them (see `AgPage`) a simple exhaustive `switch`.
@immutable
sealed class AgPageState<T> {
  const AgPageState();

  const factory AgPageState.initial() = AgPageInitial<T>;

  const factory AgPageState.loading() = AgPageLoading<T>;

  const factory AgPageState.success(T data, {bool isRefreshing}) =
      AgPageSuccess<T>;

  const factory AgPageState.empty() = AgPageEmpty<T>;

  const factory AgPageState.error(
    Object error, [
    StackTrace? stackTrace,
    T? previousData,
  ]) = AgPageError<T>;
}

/// The state before the first `AgBaseController.loadInitial` call starts.
class AgPageInitial<T> extends AgPageState<T> {
  const AgPageInitial();

  @override
  bool operator ==(Object other) => other is AgPageInitial<T>;

  @override
  int get hashCode => (AgPageInitial<T>).hashCode;

  @override
  String toString() => 'AgPageState<$T>.initial()';
}

/// The initial (first-page) load is in flight.
class AgPageLoading<T> extends AgPageState<T> {
  const AgPageLoading();

  @override
  bool operator ==(Object other) => other is AgPageLoading<T>;

  @override
  int get hashCode => (AgPageLoading<T>).hashCode;

  @override
  String toString() => 'AgPageState<$T>.loading()';
}

/// Data loaded successfully. [isRefreshing] is true while an
/// `AgBaseController.refresh` is in flight, so previously loaded [data]
/// can stay on screen instead of being replaced by a loading indicator.
class AgPageSuccess<T> extends AgPageState<T> {
  const AgPageSuccess(this.data, {this.isRefreshing = false});

  final T data;
  final bool isRefreshing;

  AgPageSuccess<T> copyWith({T? data, bool? isRefreshing}) {
    return AgPageSuccess<T>(
      data ?? this.data,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  // Uses deep equality (not plain `==`) so `T` being a List/Map/Set of
  // value objects — the common case, e.g. AgListController's `List<Item>`
  // — compares by content rather than identity.
  @override
  bool operator ==(Object other) =>
      other is AgPageSuccess<T> &&
      _dataEquality.equals(other.data, data) &&
      other.isRefreshing == isRefreshing;

  @override
  int get hashCode => Object.hash(_dataEquality.hash(data), isRefreshing);

  @override
  String toString() =>
      'AgPageState<$T>.success($data, isRefreshing: $isRefreshing)';
}

/// The load succeeded but produced no data to show.
class AgPageEmpty<T> extends AgPageState<T> {
  const AgPageEmpty();

  @override
  bool operator ==(Object other) => other is AgPageEmpty<T>;

  @override
  int get hashCode => (AgPageEmpty<T>).hashCode;

  @override
  String toString() => 'AgPageState<$T>.empty()';
}

/// The load failed. [previousData] preserves whatever was on screen before
/// the failing load/refresh, if any — a load-more or refresh failure is a
/// distinct concept and never reaches this state (see `AgPaginationState`).
class AgPageError<T> extends AgPageState<T> {
  const AgPageError(this.error, [this.stackTrace, this.previousData]);

  final Object error;
  final StackTrace? stackTrace;
  final T? previousData;

  @override
  bool operator ==(Object other) =>
      other is AgPageError<T> &&
      other.error == error &&
      _dataEquality.equals(other.previousData, previousData);

  @override
  int get hashCode => Object.hash(error, _dataEquality.hash(previousData));

  @override
  String toString() => 'AgPageState<$T>.error($error)';
}

/// Convenience accessors over [AgPageState].
extension AgPageStateX<T> on AgPageState<T> {
  /// The current data, if this state carries any (only [AgPageSuccess]
  /// does).
  T? get dataOrNull => switch (this) {
    AgPageSuccess<T>(:final data) => data,
    _ => null,
  };

  /// True for [AgPageInitial] and [AgPageLoading].
  bool get isLoading => switch (this) {
    AgPageInitial<T>() || AgPageLoading<T>() => true,
    _ => false,
  };

  /// True for [AgPageSuccess].
  bool get isSuccess => this is AgPageSuccess<T>;

  /// True for [AgPageError].
  bool get isError => this is AgPageError<T>;

  /// True for [AgPageEmpty].
  bool get isEmpty => this is AgPageEmpty<T>;
}
