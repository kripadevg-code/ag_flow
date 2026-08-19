/// Resolves an `AgEndpoint`'s `{token}` path template against a set of
/// path parameter values.
class AgPathResolver {
  AgPathResolver._();

  static final RegExp _token = RegExp(r'\{(\w+)\}');

  /// Substitutes every `{token}` in [template] with its value from
  /// [params]. Throws [AgMissingPathParameterException] — without ever
  /// building a partially-resolved URL — if any token has no
  /// corresponding, non-null entry.
  static String resolve(String template, Map<String, dynamic> params) {
    final missing = <String>[];
    final resolved = template.replaceAllMapped(_token, (match) {
      final name = match.group(1)!;
      final value = params[name];
      if (!params.containsKey(name) || value == null) {
        missing.add(name);
        return match.group(0)!;
      }
      return Uri.encodeComponent(value.toString());
    });

    if (missing.isNotEmpty) {
      throw AgMissingPathParameterException(
        parameterNames: missing,
        endpointTemplate: template,
      );
    }

    return resolved;
  }
}

/// Thrown when an `AgEndpoint`'s path template has one or more `{token}`s
/// with no corresponding path parameter value supplied on the request.
class AgMissingPathParameterException implements Exception {
  const AgMissingPathParameterException({
    required this.parameterNames,
    required this.endpointTemplate,
  });

  /// The names of the missing path parameters, in template order.
  final List<String> parameterNames;

  /// The endpoint path template that was being resolved.
  final String endpointTemplate;

  @override
  String toString() {
    final label = parameterNames.length == 1 ? 'parameter' : 'parameters';
    return 'Missing required path $label: ${parameterNames.join(', ')}\n'
        'Endpoint: $endpointTemplate';
  }
}
