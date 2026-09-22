import 'package:ag_flow/src/network/ag_request.dart';
import 'package:ag_flow/src/network/ag_response.dart';
import 'package:ag_flow/src/network/api_provider.dart';
import 'package:ag_flow/src/service/ag_envelope.dart';
import 'package:meta/meta.dart';

/// Base class for every AG service.
///
/// Services own API communication: they build `AgRequest`s against
/// reusable `AgEndpoint`s and send them through the single shared
/// [ApiProvider]. A service must never construct a raw URL or use an HTTP
/// client directly.
///
/// [envelope], [decodeListPayload], and [decodeItemPayload] exist so that
/// *every* read decodes the same way — including the feature-specific
/// methods (`searchProducts`, `getByCategory`, ...) that no mixin can
/// anticipate. Without them, each bespoke method re-implements unwrapping
/// and casting by hand, and modules drift apart exactly where the
/// framework stops looking.
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

  /// Where the payload sits inside this backend's response bodies.
  /// Defaults to "the body is the payload" — correct for most REST APIs.
  ///
  /// Override once per Service, or once app-wide by putting it on your
  /// own intermediate `AgBaseService` subclass that every Service extends.
  AgEnvelope get envelope => AgEnvelope.raw;

  /// Sends [request] through the shared [ApiProvider].
  @protected
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
  }) {
    return apiProvider.send<D>(request, decode: decode);
  }

  /// Unwraps [body] via [envelope] and decodes the resulting JSON array
  /// with [fromJson].
  @protected
  List<D> decodeListPayload<D>(
    Object? body,
    D Function(Map<String, dynamic> json) fromJson,
  ) {
    final payload = envelope.payloadOf(body);
    if (payload is! List) {
      throw AgEnvelopeException(
        'Expected a JSON array payload but found ${payload.runtimeType}. '
        'If this backend wraps its collections (e.g. {"data": [...]}), '
        'declare that by overriding `envelope` on this Service.',
      );
    }
    return payload
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  /// Unwraps [body] via [envelope] and decodes the resulting JSON object
  /// with [fromJson].
  @protected
  D decodeItemPayload<D>(
    Object? body,
    D Function(Map<String, dynamic> json) fromJson,
  ) {
    final payload = envelope.payloadOf(body);
    if (payload is! Map<String, dynamic>) {
      throw AgEnvelopeException(
        'Expected a JSON object payload but found ${payload.runtimeType}. '
        'If this backend wraps single resources (e.g. {"data": {...}}), '
        'declare that by overriding `envelope` on this Service.',
      );
    }
    return fromJson(payload);
  }

  /// Sends [request] and decodes the response as a list — the one-liner
  /// every feature-specific "fetch many" method should be.
  @protected
  Future<List<D>> fetchList<D>(
    AgRequest request,
    D Function(Map<String, dynamic> json) fromJson,
  ) async {
    final response = await send<Object?>(request, decode: (json) => json);
    return decodeListPayload(response.data, fromJson);
  }

  /// Sends [request] and decodes the response as a single object — the
  /// one-liner every feature-specific "fetch one" method should be.
  @protected
  Future<D> fetchItem<D>(
    AgRequest request,
    D Function(Map<String, dynamic> json) fromJson,
  ) async {
    final response = await send<Object?>(request, decode: (json) => json);
    return decodeItemPayload(response.data, fromJson);
  }
}
