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
  /// Future<List<Post>> list({int page = 1}) async {
  ///   final request = AgRequest(
  ///     endpoint: PostEndpoints.posts,
  ///     queryParams: pagination!.query(page),
  ///   );
  ///   // ...
  /// }
  /// ```
  AgPagination? get pagination => null;

  /// Sends [request] through the shared [ApiProvider].
  @protected
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
  }) {
    return apiProvider.send<D>(request, decode: decode);
  }
}
