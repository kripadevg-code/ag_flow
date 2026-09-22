/// Configures `AgLoggingInterceptor`'s output and sensitive-value masking.
class AgLogOptions {
  const AgLogOptions({
    this.enabled = true,
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

  /// Whether request/response logging is on at all.
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
