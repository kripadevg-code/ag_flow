import 'package:ag_flow/src/network/ag_endpoint.dart';
import 'package:ag_flow/src/network/ag_http_method.dart';
import 'package:ag_flow/src/network/ag_path_resolver.dart';

/// A single form file to upload as part of a multipart [AgRequest].
class AgFormFile {
  const AgFormFile({
    required this.fieldName,
    required this.filePath,
    this.fileName,
    this.contentType,
  });

  final String fieldName;
  final String filePath;
  final String? fileName;

  /// A MIME type string, e.g. `'image/png'`.
  final String? contentType;
}

/// A concrete, per-call request built from a reusable [AgEndpoint].
///
/// [AgRequest] carries every request-specific value — path/query
/// parameters, headers, body, form-data — so two [AgRequest]s built from
/// the same [AgEndpoint] never interfere with each other, even in flight
/// concurrently: the endpoint's path template is never mutated, only read.
class AgRequest {
  AgRequest({
    required this.endpoint,
    AgHttpMethod? method,
    this.pathParams = const {},
    this.queryParams = const {},
    this.headers = const {},
    this.body,
    this.formFields,
    this.formFiles,
  }) : method = method ?? endpoint.methods.first {
    // Real, unconditional checks rather than `assert` — these are
    // caller-contract violations that must still be caught in release
    // builds, not just during development.
    if (!endpoint.supports(this.method)) {
      throw AgUnsupportedMethodException(
        endpoint: endpoint,
        method: this.method,
      );
    }
    if (body != null && (formFields != null || formFiles != null)) {
      throw ArgumentError(
        'An AgRequest cannot have both a body and form-data.',
      );
    }
  }

  /// The endpoint this request targets.
  final AgEndpoint endpoint;

  /// The HTTP method for this specific call. Defaults to the endpoint's
  /// first supported method.
  final AgHttpMethod method;

  /// Values for this endpoint's `{token}` path parameters.
  final Map<String, dynamic> pathParams;

  /// Query parameters, kept entirely separate from [pathParams].
  final Map<String, dynamic> queryParams;

  /// Request-specific headers.
  final Map<String, String> headers;

  /// The request body, for non-multipart requests.
  final Object? body;

  /// Multipart form fields. Mutually exclusive with [body].
  final Map<String, String>? formFields;

  /// Multipart form files. Mutually exclusive with [body].
  final List<AgFormFile>? formFiles;

  /// Whether this is a multipart/form-data request.
  bool get isMultipart => formFields != null || formFiles != null;

  /// Resolves [endpoint]'s path template against [pathParams].
  String resolvePath() => AgPathResolver.resolve(endpoint.path, pathParams);
}

/// Thrown when an [AgRequest] is built with a [AgRequest.method] its
/// [AgEndpoint] doesn't declare support for.
class AgUnsupportedMethodException implements Exception {
  const AgUnsupportedMethodException({
    required this.endpoint,
    required this.method,
  });

  final AgEndpoint endpoint;
  final AgHttpMethod method;

  @override
  String toString() => 'Endpoint $endpoint does not support ${method.name}.';
}
