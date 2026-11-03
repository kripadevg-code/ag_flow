import 'package:ag_flow/src/network/ag_auth.dart';
import 'package:dio/dio.dart';

/// Adds [AgAuth]'s token header to every request whose endpoint has
/// `auth: true`, and on a `401` refreshes the token once and sends the
/// request again. Internal to `DioApiProvider` — not exported, so no dio type
/// reaches the app.
class AgAuthInterceptor extends Interceptor {
  AgAuthInterceptor(this.auth, this._dio);

  final AgAuth auth;
  final Dio _dio;

  /// `RequestOptions.extra` key carrying the endpoint's `auth` flag.
  static const authKey = 'ag_auth';

  /// Marks a header this interceptor set, so a re-sent request (a retry, or
  /// after a refresh) gets the current token instead of keeping the old one.
  static const _ownHeaderKey = 'ag_auth_own_header';

  /// Marks a request already sent again after a refresh — it is never sent
  /// a third time, so a backend that keeps answering `401` can't loop.
  static const _resentKey = 'ag_auth_resent';

  /// The refresh in progress; every `401` that arrives meanwhile waits for it
  /// instead of starting its own.
  Future<bool>? _refreshing;

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

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    // Only a 401 on a request that carried this interceptor's token: a
    // request sent without a token, or with the caller's own header, isn't
    // ours to refresh.
    if (err.response?.statusCode != 401 ||
        options.extra[_ownHeaderKey] != true ||
        options.extra[_resentKey] == true) {
      return handler.next(err);
    }
    try {
      final current = await auth.readToken();
      // No token left: a failed refresh already logged the user out while
      // this request was in flight — don't refresh (and log out) again.
      if (current == null || current.isEmpty) return handler.next(err);
      // A refresh that finished while this request was in flight already
      // fixed it: the stored token is no longer the one it was sent with.
      final alreadyRefreshed = auth.headerValue(current) != options.headers[auth.headerName];
      if (!alreadyRefreshed && !await (_refreshing ??= _refresh())) {
        return handler.next(err);
      }
      options.extra[_resentKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (resendError) {
      handler.next(resendError);
    } on Object {
      handler.next(err);
    }
  }

  Future<bool> _refresh() async {
    try {
      var refreshed = false;
      try {
        refreshed = await auth.refreshToken();
      } on Object {
        refreshed = false;
      }
      if (!refreshed) {
        // Log out even when clearing fails — the session is over either way.
        try {
          await auth.clearToken();
        } finally {
          await auth.onLoggedOut();
        }
      }
      return refreshed;
    } finally {
      _refreshing = null;
    }
  }

  static bool _hasHeader(RequestOptions options, String name) {
    final lower = name.toLowerCase();
    return options.headers.keys.any((key) => key.toLowerCase() == lower);
  }
}
