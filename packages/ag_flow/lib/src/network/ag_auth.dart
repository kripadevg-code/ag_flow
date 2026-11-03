import 'dart:async';

/// How the app's requests are authorized — supplied by the app, because
/// every backend stores and names its tokens differently.
///
/// Pass one to `ApiProvider(auth: ...)` and every request gets the token
/// header automatically; Services and Repos never touch a token. Leave
/// `auth` out and nothing changes: no header, no interceptor.
///
/// ```dart
/// class AppAuth extends AgAuth {
///   AppAuth(this._storage);
///
///   final SecureStorage _storage;
///
///   @override
///   Future<String?> readToken() => _storage.read('access_token');
/// }
///
/// final api = ApiProvider(baseUrl: 'https://api.example.com', auth: AppAuth(storage));
/// ```
///
/// A public endpoint (login, sign-up, a public catalogue) opts out with
/// `AgEndpoint('/login', auth: false)`. A header the request sets itself is
/// never overwritten.
///
/// When a request carrying the token gets a `401`, [refreshToken] runs once —
/// requests that fail together share that one refresh — and each request is
/// sent again, once, with the new token. When the refresh fails,
/// [clearToken] and then [onLoggedOut] run, and the requests fail with their
/// `401`. Without a [refreshToken] override, every such `401` counts as a
/// failed refresh.
abstract class AgAuth {
  /// Const so a stateless implementation can be a compile-time constant.
  const AgAuth();

  /// The current access token, or `null` when the user is logged out — a
  /// `null` token sends the request without the header.
  FutureOr<String?> readToken();

  /// Gets a new access token after a `401` and stores it, so the next
  /// [readToken] returns it. Return `true` when it worked, `false` (or throw)
  /// when it didn't. Defaults to `false`: no refresh.
  ///
  /// Send the refresh call itself to an `auth: false` endpoint, so its own
  /// `401` can never start another refresh.
  FutureOr<bool> refreshToken() => false;

  /// Removes the stored tokens after a failed refresh. Defaults to nothing.
  FutureOr<void> clearToken() {}

  /// Runs after [clearToken] when a refresh failed — the place to send the
  /// user to the login screen. Defaults to nothing.
  FutureOr<void> onLoggedOut() {}

  /// The header the token is sent in. Defaults to `Authorization`.
  String get headerName => 'Authorization';

  /// The header's value for [token]. Defaults to `Bearer <token>`.
  String headerValue(String token) => 'Bearer $token';
}
