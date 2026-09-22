import 'package:ag_flow/src/arguments/ag_arguments.dart';
import 'package:ag_flow/src/controller/ag_base_controller.dart';
import 'package:ag_flow/src/navigation/ag_navigator.dart';
import 'package:flutter/foundation.dart';

/// Base class for detail modules: an [AgBaseController] that also
/// resolves its typed navigation argument [A].
///
/// The argument comes from the route's **path parameters** by way of
/// [argumentsFromPath], which is what makes a detail page work from a
/// deep link, a notification, or a reloaded web URL — not only from an
/// in-app push. `AgNavigator.extra` is accepted as well, for a payload
/// that genuinely cannot be expressed in a URL.
///
/// ```dart
/// class ProductDetailsController
///     extends AgDetailController<Product, ProductDetailsPageArgument> {
///   @override
///   ProductDetailsPageArgument? argumentsFromPath(
///     Map<String, String> pathParameters,
///   ) => ProductDetailsPageArgument.fromPathParameters(pathParameters);
/// }
/// ```
///
/// A single type parameter list (`T`, `A`) here is what lets `AgBasePage`
/// stay a one-type-parameter class for both collection and detail
/// modules — see `AgBasePage`.
abstract class AgDetailController<T, A extends Object>
    extends AgBaseController<T> {
  /// Captures the route's parameters at construction — which happens
  /// inside the binding, while the route being entered is still the
  /// current one. Reading them later (on first access to [arguments])
  /// would race any navigation that happened in between.
  AgDetailController({super.autoLoadOnInit})
    : _pathParameters = AgNavigator.pathParameters,
      _extra = AgNavigator.extra;

  final Map<String, String> _pathParameters;
  final Object? _extra;

  /// The path parameters this controller's route was entered with.
  @protected
  Map<String, String> get pathParameters => _pathParameters;

  /// Builds this controller's argument from the route's path parameters.
  ///
  /// Override it in any detail module whose route declares parameters —
  /// the generator writes this for you. Returning null falls back to
  /// [AgNavigator.extra].
  @protected
  A? argumentsFromPath(Map<String, String> pathParameters) => null;

  /// The navigation argument this controller's page was opened with.
  late final A arguments = _resolveArguments();

  A _resolveArguments() {
    final fromPath = argumentsFromPath(_pathParameters);
    if (fromPath != null) return fromPath;
    final extra = _extra;
    if (extra is A) return extra;
    throw AgArgumentError(
      expectedType: A,
      actualValue: extra,
      pathParameters: _pathParameters,
    );
  }
}
