import 'package:ag_flow/src/network/ag_auth.dart';
import 'package:dio/dio.dart';

/// Adds [AgAuth]'s token header to every request whose endpoint has
/// `auth: true`. Internal to `DioApiProvider` — not exported, so no dio type
/// reaches the app.
class AgAuthInterceptor extends Interceptor {
  AgAuthInterceptor(this.auth);

  final AgAuth auth;

  /// `RequestOptions.extra` key carrying the endpoint's `auth` flag.
  static const authKey = 'ag_auth';

  /// Marks a header this interceptor set, so a re-sent request (a retry, or
  /// after a refresh) gets the current token instead of keeping the old one.
  static const _ownHeaderKey = 'ag_auth_own_header';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final ownHeader = options.extra[_ownHeaderKey] == true;
    if (options.extra[authKey] == false || (!ownHeader && _hasHeader(options, auth.headerName))) {
      return handler.next(options);
    }
    try {
      final token = await auth.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers[auth.headerName] = auth.headerValue(token);
        options.extra[_ownHeaderKey] = true;
      } else if (ownHeader) {
        options.headers.remove(auth.headerName);
        options.extra.remove(_ownHeaderKey);
      }
      handler.next(options);
    } on Object catch (error, stackTrace) {
      // A storage failure must surface as a normal request error, not an
      // unhandled exception that leaves the request hanging.
      handler.reject(
        DioException(requestOptions: options, error: error, stackTrace: stackTrace),
      );
    }
  }

  static bool _hasHeader(RequestOptions options, String name) {
    final lower = name.toLowerCase();
    return options.headers.keys.any((key) => key.toLowerCase() == lower);
  }
}
