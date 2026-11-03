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
abstract class AgAuth {
  /// Const so a stateless implementation can be a compile-time constant.
  const AgAuth();

  /// The current access token, or `null` when the user is logged out — a
  /// `null` token sends the request without the header.
  FutureOr<String?> readToken();

  /// The header the token is sent in. Defaults to `Authorization`.
  String get headerName => 'Authorization';

  /// The header's value for [token]. Defaults to `Bearer <token>`.
  String headerValue(String token) => 'Bearer $token';
}
