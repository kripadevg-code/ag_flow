import 'package:ag_flow/src/network/ag_api_exception.dart';

/// An app-level failure raised by a repository via `AgBaseRepo.guard`.
///
/// Controllers and pages see this type instead of the Service's transport
/// errors, so they can react to [kind] (show a login screen on
/// [AgRepoErrorKind.unauthorized], an offline banner on
/// [AgRepoErrorKind.network], ...) without knowing anything about HTTP.
class AgRepoException implements Exception {
  const AgRepoException(this.cause, {this.kind = AgRepoErrorKind.unknown});

  /// Wraps [error], classifying it into a [kind].
  ///
  /// An [AgApiException] is classified by its type and status code; a
  /// [FormatException] or [TypeError] (a response that didn't decode into
  /// the model) is [AgRepoErrorKind.badResponse]; anything else is
  /// [AgRepoErrorKind.unknown].
  factory AgRepoException.from(Object error) {
    if (error is AgRepoException) return error;
    return AgRepoException(error, kind: _kindOf(error));
  }

  /// The original error that was caught.
  final Object cause;

  /// What kind of failure this is.
  final AgRepoErrorKind kind;

  /// A short, user-readable description of [kind].
  ///
  /// English only — an app that localizes passes its own text to
  /// `AgError.message` from the page's `errorBuilder`.
  String get message => switch (kind) {
    AgRepoErrorKind.network => 'No connection. Check your network.',
    AgRepoErrorKind.timeout => 'The server took too long to respond.',
    AgRepoErrorKind.cancelled => 'The request was cancelled.',
    AgRepoErrorKind.unauthorized => 'You are not allowed to do this.',
    AgRepoErrorKind.notFound => 'Not found.',
    AgRepoErrorKind.rejected => 'The request was rejected.',
    AgRepoErrorKind.server => 'Something went wrong on the server.',
    AgRepoErrorKind.badResponse => 'The server sent an unexpected response.',
    AgRepoErrorKind.unknown => 'Something went wrong.',
  };

  static AgRepoErrorKind _kindOf(Object error) {
    if (error is FormatException || error is TypeError) {
      return AgRepoErrorKind.badResponse;
    }
    if (error is! AgApiException) return AgRepoErrorKind.unknown;
    return switch (error.type) {
      AgApiErrorType.connection => AgRepoErrorKind.network,
      AgApiErrorType.timeout => AgRepoErrorKind.timeout,
      AgApiErrorType.cancelled => AgRepoErrorKind.cancelled,
      AgApiErrorType.response ||
      AgApiErrorType.unknown => switch (error.statusCode) {
        401 || 403 => AgRepoErrorKind.unauthorized,
        404 => AgRepoErrorKind.notFound,
        final code? when code >= 500 => AgRepoErrorKind.server,
        final code? when code >= 400 => AgRepoErrorKind.rejected,
        _ => AgRepoErrorKind.unknown,
      },
    };
  }

  @override
  String toString() => 'AgRepoException(${kind.name}): $cause';
}

/// The app-level kind of an [AgRepoException].
enum AgRepoErrorKind {
  /// The server could not be reached.
  network,

  /// The server took too long.
  timeout,

  /// The request was cancelled.
  cancelled,

  /// 401 or 403.
  unauthorized,

  /// 404.
  notFound,

  /// Any other 4xx — the server refused the request as sent.
  rejected,

  /// 5xx.
  server,

  /// The response didn't decode into the expected model.
  badResponse,

  /// Anything else.
  unknown,
}
