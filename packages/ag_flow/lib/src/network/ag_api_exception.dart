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
    );
  }

  final int? statusCode;
  final String message;
  final Object? responseBody;
  final Duration? duration;

  @override
  String toString() =>
      'AgApiException(statusCode: $statusCode, message: $message)';
}
