import 'package:ag_flow/src/network/ag_http_method.dart';

/// A reusable, immutable API contract: a path template plus the HTTP
/// method(s) it supports.
///
/// [AgEndpoint] never holds request-specific values — path/query
/// parameter values, headers, or a body all belong on a per-call
/// `AgRequest`. This is what keeps a single endpoint definition safely
/// shareable across every Service that needs it, with no risk of
/// concurrent requests interfering with each other.
class AgEndpoint {
  const AgEndpoint(
    this.path, {
    this.methods = const {AgHttpMethod.get},
    this.baseUrlOverride,
  });

  /// The path template, e.g. `/products/{id}`.
  final String path;

  /// The HTTP methods this endpoint supports.
  final Set<AgHttpMethod> methods;

  /// Overrides `ApiProvider`'s configured base URL for this endpoint only
  /// (e.g. a third-party or legacy host).
  final String? baseUrlOverride;

  /// Whether this endpoint supports [method].
  bool supports(AgHttpMethod method) => methods.contains(method);

  @override
  String toString() => 'AgEndpoint($path, methods: $methods)';
}
