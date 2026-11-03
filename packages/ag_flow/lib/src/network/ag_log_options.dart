import 'package:flutter/foundation.dart';

/// Configures `AgLoggingInterceptor`'s output and sensitive-value masking.
class AgLogOptions {
  const AgLogOptions({
    this.enabled = !kReleaseMode,
    this.logRequestBody = false,
    this.logResponseBody = false,
    this.maskedHeaderKeys = const {'authorization', 'cookie', 'set-cookie'},
    this.maskedBodyKeys = const {
      'password',
      'secret',
      'token',
      'accesstoken',
      'refreshtoken',
    },
    this.logger,
  });

  /// Whether request/response logging is on at all. Off by default in release
  /// builds: `debugPrint` is not stripped there, so request URLs (query
  /// strings included) would reach the device log.
  final bool enabled;

  /// Whether to include the request body in logs (masked per
  /// [maskedBodyKeys]).
  final bool logRequestBody;

  /// Whether to include the response body in logs (masked per
  /// [maskedBodyKeys]).
  final bool logResponseBody;

  /// Header names (case-insensitive) whose values are replaced with `***`.
  final Set<String> maskedHeaderKeys;

  /// Body/JSON field names (case-insensitive) whose values are replaced
  /// with `***`.
  final Set<String> maskedBodyKeys;

  /// Sink for log lines. Defaults to `debugPrint` (from
  /// `package:flutter/foundation.dart`).
  final void Function(String message)? logger;
}
