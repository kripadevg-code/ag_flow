/// An HTTP method.
///
/// An open class of constants rather than a closed `enum` — a particular
/// backend may require an unusual verb, and this stays representable
/// (`const AgHttpMethod('TRACE')`) without a breaking release of this
/// package.
///
/// Deliberately has no custom `==`/`hashCode` override: `AgEndpoint` must
/// stay declarable as a compile-time `static const` (the endpoint rules
/// require endpoints to be immutable, shared, defined-once values), and
/// Dart disallows const set/map elements whose type overrides `==`.
/// Instead, always construct instances with `const` — e.g.
/// `const AgHttpMethod('TRACE')` — and Dart's constant canonicalization
/// guarantees two such expressions with the same [name] are the exact
/// same object, so plain identity equality (the default) already does the
/// right thing.
class AgHttpMethod {
  const AgHttpMethod(this.name);

  /// The verb, e.g. `'GET'`.
  final String name;

  static const get = AgHttpMethod('GET');
  static const post = AgHttpMethod('POST');
  static const put = AgHttpMethod('PUT');
  static const patch = AgHttpMethod('PATCH');
  static const delete = AgHttpMethod('DELETE');
  static const head = AgHttpMethod('HEAD');
  static const options = AgHttpMethod('OPTIONS');

  @override
  String toString() => name;
}
