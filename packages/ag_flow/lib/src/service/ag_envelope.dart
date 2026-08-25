/// Where the actual payload sits inside a response body.
///
/// Backends disagree about this constantly — some return a bare array,
/// some wrap it (`{"data": [...]}`, `{"results": [...]}`), some nest it
/// (`{"response": {"items": [...]}}`). That difference is a property of
/// the *backend*, not of any one feature module, so AG models it as a
/// value a Service declares once rather than something every method
/// re-implements by hand.
///
/// Declare it once on a Service (or once app-wide, by giving your own
/// `AgBaseService` subclass a default) and every read that Service
/// performs unwraps the same way.
abstract class AgEnvelope {
  const AgEnvelope();

  /// The payload sits at [key] on a JSON object, e.g. `"data"` for
  /// `{"data": [...]}`.
  const factory AgEnvelope.key(String key) = _KeyedEnvelope;

  /// The payload sits at a nested path, e.g. `['response', 'items']` for
  /// `{"response": {"items": [...]}}`.
  const factory AgEnvelope.path(List<String> keys) = _PathEnvelope;

  /// Anything the named cases don't cover.
  const factory AgEnvelope.custom(Object? Function(Object? body) extract) =
      _CustomEnvelope;

  /// The body *is* the payload — a bare array or bare object. The
  /// default, and correct for most REST APIs.
  static const AgEnvelope raw = _RawEnvelope();

  /// Extracts the payload from a decoded response [body].
  Object? payloadOf(Object? body);

  /// Reads a sibling field from the *envelope itself* rather than the
  /// payload — e.g. a `nextCursor`/`total` that lives alongside the data
  /// in a wrapped response. Returns null when the body isn't a map, or
  /// the key is absent.
  ///
  /// This is what lets a cursor-paginated, enveloped backend work without
  /// a bespoke Service: `AgPageStrategy` reads its next-page token
  /// through here.
  Object? metaOf(Object? body, String key) {
    if (body is Map<String, dynamic>) return body[key];
    return null;
  }
}

class _RawEnvelope extends AgEnvelope {
  const _RawEnvelope();

  @override
  Object? payloadOf(Object? body) => body;
}

class _KeyedEnvelope extends AgEnvelope {
  const _KeyedEnvelope(this.key);

  final String key;

  @override
  Object? payloadOf(Object? body) {
    if (body is Map<String, dynamic>) return body[key];
    throw AgEnvelopeException(
      'Expected a JSON object with a "$key" field, but the response body '
      'was ${body.runtimeType}.',
    );
  }
}

class _PathEnvelope extends AgEnvelope {
  const _PathEnvelope(this.keys);

  final List<String> keys;

  @override
  Object? payloadOf(Object? body) {
    var current = body;
    for (final key in keys) {
      if (current is! Map<String, dynamic>) {
        throw AgEnvelopeException(
          'Expected a JSON object at "${keys.join('.')}" while unwrapping '
          'the response, but found ${current.runtimeType}.',
        );
      }
      current = current[key];
    }
    return current;
  }
}

class _CustomEnvelope extends AgEnvelope {
  const _CustomEnvelope(this._extract);

  final Object? Function(Object? body) _extract;

  @override
  Object? payloadOf(Object? body) => _extract(body);
}

/// Thrown when a response body doesn't have the shape its [AgEnvelope]
/// expects — a named, actionable error rather than a bare cast failure
/// somewhere inside a decode callback.
class AgEnvelopeException implements Exception {
  const AgEnvelopeException(this.message);

  final String message;

  @override
  String toString() => 'AgEnvelopeException: $message';
}
