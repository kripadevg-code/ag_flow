import 'dart:async';

import 'package:ag_flow/src/network/ag_endpoint.dart';
import 'package:ag_flow/src/network/ag_http_method.dart';
import 'package:ag_flow/src/network/ag_request.dart';
import 'package:ag_flow/src/network/ag_response.dart';
import 'package:ag_flow/src/network/api_provider.dart';
import 'package:ag_flow/src/service/ag_pagination.dart';
import 'package:meta/meta.dart';

/// Base class for every AG service.
///
/// Services own API communication: they build `AgRequest`s against
/// reusable `AgEndpoint`s and send them through the single shared
/// [ApiProvider]. A service must never construct a raw URL or use an HTTP
/// client directly.
///
/// AG provides the shape, never the bodies: a Service mixes in the action
/// contracts its backend supports (`AgListMixin`, `AgCreateMixin`, ...),
/// writes each body itself, and adds feature-specific methods
/// (`filterProducts`, `search`, ...) as ordinary methods.
///
/// ---
/// ### Accessing a service anywhere — no generics
///
/// Every concrete service should expose an `instance` static getter so it
/// can be resolved from [AgLocator] without any generic syntax:
///
/// ```dart
/// class AuthService extends AgBaseService {
///   // One line — add this to every service.
///   static AuthService get instance => AgLocator.find<AuthService>();
///
///   AuthService(super.apiProvider);
///   // ...
/// }
/// ```
///
/// Then anywhere in the app — a guard, a controller, a repo:
///
/// ```dart
/// final authService = AuthService.instance;
/// ```
///
/// Dart infers the type from the left-hand side. No `<AuthService>`
/// needed at the call site.
///
/// The naming convention is intentional:
/// - Controllers use `.find`    — they are scoped to a route's lifetime.
/// - Services use `.instance`   — they are permanent app-wide singletons.
abstract class AgBaseService {
  const AgBaseService(this.apiProvider);

  @protected
  final ApiProvider apiProvider;

  /// How this backend pages its collections, or null (the default) when
  /// it returns everything at once.
  ///
  /// Opt in with one line, and use it from your own `list` body:
  ///
  /// ```dart
  /// @override
  /// AgPagination? get pagination => const AgPageNumberPagination();
  ///
  /// @override
  /// Future<List<Post>> list({int page = 1}) => get(
  ///   PostEndpoints.posts,
  ///   queryParams: pagination!.query(page),
  ///   decode: (json) => [
  ///     for (final item in json! as List<Object?>)
  ///       Post.fromJson(item! as Map<String, dynamic>),
  ///   ],
  /// );
  /// ```
  AgPagination? get pagination => null;

  /// Sends a GET to [endpoint] and returns the decoded body.
  ///
  /// The five verb methods are how an action body talks to the backend:
  /// each builds the `AgRequest`, sends it through [apiProvider] and
  /// returns only the data. [decode] turns the JSON body into [D] — unwrap
  /// an enveloped response there. It may return a Future, so a large body
  /// can be decoded off the UI thread with Flutter's `compute`:
  ///
  /// ```dart
  /// Future<List<Post>> list({int page = 1}) => get(
  ///   PostEndpoints.posts,
  ///   decode: (json) => compute(Post.listFromJson, json),
  /// );
  /// ```
  ///
  /// dio already parses large JSON text in a background isolate, so this
  /// is only worth it when building the objects is itself slow. Use [send]
  /// when you need the full response (status code, headers) or form data.
  @protected
  Future<D> get<D>(
    AgEndpoint endpoint, {
    Map<String, dynamic> pathParams = const {},
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    FutureOr<D> Function(Object? json)? decode,
  }) => _data(
    AgHttpMethod.get,
    endpoint,
    pathParams: pathParams,
    queryParams: queryParams,
    headers: headers,
    decode: decode,
  );

  /// Sends a POST of [body] to [endpoint] and returns the decoded body.
  @protected
  Future<D> post<D>(
    AgEndpoint endpoint, {
    Object? body,
    Map<String, dynamic> pathParams = const {},
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    FutureOr<D> Function(Object? json)? decode,
  }) => _data(
    AgHttpMethod.post,
    endpoint,
    body: body,
    pathParams: pathParams,
    queryParams: queryParams,
    headers: headers,
    decode: decode,
  );

  /// Sends a PUT of [body] to [endpoint] and returns the decoded body.
  @protected
  Future<D> put<D>(
    AgEndpoint endpoint, {
    Object? body,
    Map<String, dynamic> pathParams = const {},
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    FutureOr<D> Function(Object? json)? decode,
  }) => _data(
    AgHttpMethod.put,
    endpoint,
    body: body,
    pathParams: pathParams,
    queryParams: queryParams,
    headers: headers,
    decode: decode,
  );

  /// Sends a PATCH of [body] to [endpoint] and returns the decoded body.
  @protected
  Future<D> patch<D>(
    AgEndpoint endpoint, {
    Object? body,
    Map<String, dynamic> pathParams = const {},
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    FutureOr<D> Function(Object? json)? decode,
  }) => _data(
    AgHttpMethod.patch,
    endpoint,
    body: body,
    pathParams: pathParams,
    queryParams: queryParams,
    headers: headers,
    decode: decode,
  );

  /// Sends a DELETE to [endpoint] and returns the decoded body, if any.
  @protected
  Future<D> delete<D>(
    AgEndpoint endpoint, {
    Object? body,
    Map<String, dynamic> pathParams = const {},
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    FutureOr<D> Function(Object? json)? decode,
  }) => _data(
    AgHttpMethod.delete,
    endpoint,
    body: body,
    pathParams: pathParams,
    queryParams: queryParams,
    headers: headers,
    decode: decode,
  );

  Future<D> _data<D>(
    AgHttpMethod method,
    AgEndpoint endpoint, {
    required Map<String, dynamic> pathParams,
    required Map<String, dynamic> queryParams,
    required Map<String, String> headers,
    required FutureOr<D> Function(Object? json)? decode,
    Object? body,
  }) async {
    final response = await send<Object?>(
      AgRequest(
        endpoint: endpoint,
        method: method,
        pathParams: pathParams,
        queryParams: queryParams,
        headers: headers,
        body: body,
      ),
    );
    final json = response.data;
    return decode != null ? await decode(json) : json as D;
  }

  /// Sends [request] through the shared [ApiProvider] and returns the
  /// full response — for when the data alone is not enough.
  @protected
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
  }) {
    return apiProvider.send<D>(request, decode: decode);
  }
}
