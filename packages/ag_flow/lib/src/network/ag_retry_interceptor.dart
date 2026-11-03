import 'package:dio/dio.dart';

/// Configures [AgRetryInterceptor]'s retry behavior.
class AgRetryPolicy {
  const AgRetryPolicy({
    this.maxAttempts = 3,
    this.retryableStatusCodes = const {502, 503, 504},
    this.retryOnConnectionError = true,
    this.backoff = const Duration(milliseconds: 300),
    this.retryableMethods = const {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'},
  });

  /// Maximum number of retry attempts (not counting the original try).
  final int maxAttempts;

  /// Response status codes that should trigger a retry.
  final Set<int> retryableStatusCodes;

  /// Whether connection errors/timeouts (no response at all) should
  /// trigger a retry.
  final bool retryOnConnectionError;

  /// Base delay before a retry; multiplied by the attempt number.
  final Duration backoff;

  /// HTTP methods (upper case) that may be retried — by default only the
  /// idempotent ones. A `POST` or `PATCH` that timed out at a gateway may
  /// already have been applied, so retrying it can create a duplicate.
  /// Add them only for endpoints that are idempotent on your backend.
  final Set<String> retryableMethods;
}

/// Retries failed requests according to an [AgRetryPolicy]. Opt-in — only
/// added to `ApiProvider` when a policy is supplied.
class AgRetryInterceptor extends Interceptor {
  AgRetryInterceptor(this._dio, this.policy);

  final Dio _dio;
  final AgRetryPolicy policy;

  static const _attemptKey = 'ag_retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    final shouldRetry =
        attempt < policy.maxAttempts &&
        policy.retryableMethods.contains(err.requestOptions.method.toUpperCase()) &&
        (_isRetryableStatus(err) || (policy.retryOnConnectionError && _isConnectionError(err)));

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(policy.backoff * (attempt + 1));
    err.requestOptions.extra[_attemptKey] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isRetryableStatus(DioException err) {
    final code = err.response?.statusCode;
    return code != null && policy.retryableStatusCodes.contains(code);
  }

  bool _isConnectionError(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout;
  }
}
