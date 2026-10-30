import 'package:ag_flow/src/network/ag_api_exception.dart';
import 'package:ag_flow/src/network/ag_cancel_token.dart';
import 'package:ag_flow/src/network/ag_endpoint.dart';
import 'package:ag_flow/src/network/ag_http_method.dart';
import 'package:ag_flow/src/network/ag_request.dart';
import 'package:ag_flow/src/network/ag_response.dart';
import 'package:ag_flow/src/network/api_provider.dart';

/// An [ApiProvider] for tests: it answers from replies set up in advance
/// and never touches the network.
///
/// Register it in place of the real provider and the whole stack above it
/// — Service, Repo, Controller — runs unchanged:
///
/// ```dart
/// final api = AgFakeApiProvider()
///   ..reply(TaskEndpoints.tasks, json: [{'id': 1, 'title': 'Write tests'}])
///   ..fail(
///     TaskEndpoints.task,
///     const AgApiException(message: 'offline', type: AgApiErrorType.connection),
///   );
/// AgLocator.put<ApiProvider>(api);
///
/// // ... run the code under test, then:
/// expect(api.requests.single.queryParams, {'_start': 0, '_limit': 20});
/// ```
///
/// A reply is matched by the endpoint's path template and the HTTP method,
/// so one reply covers every id. The latest reply for a pair wins, which
/// lets a test change the answer halfway through. A request with no reply
/// throws a [StateError] naming it — a missing reply is a bug in the test,
/// not an API error the code under test should handle.
class AgFakeApiProvider implements ApiProvider {
  final Map<String, _Reply> _replies = {};

  /// Every request sent so far, oldest first.
  final List<AgRequest> requests = [];

  /// Answers [method] requests to [endpoint] with [json], decoded by the
  /// caller's `decode` exactly as a real response body would be. A
  /// [statusCode] outside 2xx throws an [AgApiException] carrying [json]
  /// as its `responseBody`, as the real provider does.
  void reply(
    AgEndpoint endpoint, {
    AgHttpMethod method = AgHttpMethod.get,
    Object? json,
    int statusCode = 200,
    Map<String, List<String>> headers = const {},
  }) {
    replyWith(
      endpoint,
      (_) => json,
      method: method,
      statusCode: statusCode,
      headers: headers,
    );
  }

  /// Like [reply], but builds the body from each request — to echo a
  /// posted body back, or to answer per path parameter.
  void replyWith(
    AgEndpoint endpoint,
    Object? Function(AgRequest request) json, {
    AgHttpMethod method = AgHttpMethod.get,
    int statusCode = 200,
    Map<String, List<String>> headers = const {},
  }) {
    _replies[_key(method, endpoint)] = _Reply(
      json: json,
      statusCode: statusCode,
      headers: headers,
    );
  }

  /// Makes [method] requests to [endpoint] throw [error], the way the real
  /// provider reports a failed request.
  void fail(
    AgEndpoint endpoint,
    AgApiException error, {
    AgHttpMethod method = AgHttpMethod.get,
  }) {
    _replies[_key(method, endpoint)] = _Reply(error: error);
  }

  @override
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
    AgCancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    requests.add(request);
    final reply = _replies[_key(request.method, request.endpoint)];
    if (reply == null) {
      throw StateError(
        'AgFakeApiProvider: no reply for ${request.method} ${request.endpoint.path}. '
        'Set one up with reply() or fail() before sending it.',
      );
    }
    if (reply.error case final error?) throw error;

    final json = reply.json!(request);
    // The real provider rejects a non-2xx status (dio's default
    // validateStatus), so a `reply(statusCode: 404)` must fail here too.
    if (reply.statusCode < 200 || reply.statusCode > 299) {
      throw AgApiException(
        statusCode: reply.statusCode,
        message: 'Request failed with status ${reply.statusCode}',
        responseBody: json,
        type: AgApiErrorType.response,
      );
    }
    return AgResponse<D>(
      statusCode: reply.statusCode,
      data: decode != null ? decode(json) : json as D,
      headers: reply.headers,
      duration: Duration.zero,
    );
  }

  // AgHttpMethod deliberately has no `==` (it must stay usable in const
  // sets), so the method is keyed by its name.
  static String _key(AgHttpMethod method, AgEndpoint endpoint) => '${method.name} ${endpoint.path}';
}

class _Reply {
  const _Reply({
    this.json,
    this.error,
    this.statusCode = 200,
    this.headers = const {},
  });

  final Object? Function(AgRequest request)? json;
  final AgApiException? error;
  final int statusCode;
  final Map<String, List<String>> headers;
}
