import 'package:dio/dio.dart';

/// A transport/API failure surfaced by `ApiProvider`.
///
/// Callers (Services, Repos, Controllers) never see a raw [DioException] —
/// only this type, so the rest of the framework stays independent of the
/// underlying HTTP client.
class AgApiException implements Exception {
  const AgApiException({
    required this.message,
    this.statusCode,
    this.responseBody,
    this.duration,
    this.type = AgApiErrorType.unknown,
  });

  factory AgApiException.fromDioException(
    DioException error, {
    Duration? duration,
  }) {
    return AgApiException(
      statusCode: error.response?.statusCode,
      message: error.message ?? error.error?.toString() ?? 'Request failed',
      responseBody: error.response?.data,
      duration: duration,
      type: switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => AgApiErrorType.timeout,
        DioExceptionType.connectionError ||
        DioExceptionType.badCertificate => AgApiErrorType.connection,
        DioExceptionType.cancel => AgApiErrorType.cancelled,
        DioExceptionType.badResponse => AgApiErrorType.response,
        // A wildcard, not `unknown`: dio adds values in minor releases.
        _ => AgApiErrorType.unknown,
      },
    );
  }

  final int? statusCode;
  final String message;
  final Object? responseBody;
  final Duration? duration;

  /// What went wrong, without exposing dio's own exception type.
  final AgApiErrorType type;

  @override
  String toString() =>
      'AgApiException(statusCode: $statusCode, message: $message)';
}

/// The kind of failure behind an [AgApiException].
enum AgApiErrorType {
  /// The server could not be reached (no network, DNS, TLS).
  connection,

  /// Connecting, sending or receiving took too long.
  timeout,

  /// The request was cancelled through an `AgCancelToken`.
  cancelled,

  /// The server answered with an error status; see
  /// [AgApiException.statusCode].
  response,

  /// Anything else.
  unknown,
}
