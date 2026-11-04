import 'dart:convert';
import 'dart:typed_data';

import 'package:ag_flow/ag_flow.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this._statuses);

  /// Status per call, in order; the last one repeats.
  final List<int> _statuses;
  final List<Map<String, dynamic>> sent = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add(Map.of(options.headers));
    final status =
        _statuses[sent.length - 1 < _statuses.length ? sent.length - 1 : _statuses.length - 1];
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Auth extends AgAuth {
  _Auth(this.tokens);

  /// Token per read, in order; the last one repeats.
  final List<String?> tokens;
  int reads = 0;

  @override
  Future<String?> readToken() async {
    final token = tokens[reads < tokens.length ? reads : tokens.length - 1];
    reads++;
    return token;
  }
}

class _ApiKeyAuth extends AgAuth {
  @override
  String readToken() => 'k1';

  @override
  String get headerName => 'X-Api-Key';

  @override
  String headerValue(String token) => token;
}

class _BrokenAuth extends AgAuth {
  @override
  Future<String?> readToken() async => throw StateError('storage locked');
}

(DioApiProvider, _Adapter) _provider({
  AgAuth? auth,
  List<int> statuses = const [200],
  AgRetryPolicy? retryPolicy,
}) {
  final provider = DioApiProvider(
    baseUrl: 'https://api.test',
    auth: auth,
    retryPolicy: retryPolicy,
    logOptions: const AgLogOptions(enabled: false),
  );
  final adapter = _Adapter(statuses);
  provider.debugDio.httpClientAdapter = adapter;
  return (provider, adapter);
}

const _private = AgEndpoint('/me');
const _public = AgEndpoint('/login', methods: {AgHttpMethod.post}, auth: false);

String? _authHeader(Map<String, dynamic> headers) => headers['Authorization'] as String?;

void main() {
  test('without auth, requests carry no Authorization header', () async {
    final (api, adapter) = _provider();

    await api.send<Object?>(AgRequest(endpoint: _private));

    expect(_authHeader(adapter.sent.single), isNull);
    expect(
      api.debugDio.interceptors.whereType<Interceptor>().map((i) => i.runtimeType.toString()),
      isNot(contains('AgAuthInterceptor')),
    );
  });

  test('with auth, every request gets Bearer <token>', () async {
    final (api, adapter) = _provider(auth: _Auth(['t1']));

    await api.send<Object?>(AgRequest(endpoint: _private));
    await api.send<Object?>(AgRequest(endpoint: _private));

    expect(adapter.sent.map(_authHeader), ['Bearer t1', 'Bearer t1']);
  });

  test('reads the token per request, so a new login is picked up', () async {
    final (api, adapter) = _provider(auth: _Auth(['t1', 't2']));

    await api.send<Object?>(AgRequest(endpoint: _private));
    await api.send<Object?>(AgRequest(endpoint: _private));

    expect(adapter.sent.map(_authHeader), ['Bearer t1', 'Bearer t2']);
  });

  test('an endpoint with auth: false never reads or sends the token', () async {
    final auth = _Auth(['t1']);
    final (api, adapter) = _provider(auth: auth);

    await api.send<Object?>(AgRequest(endpoint: _public, method: AgHttpMethod.post));

    expect(_authHeader(adapter.sent.single), isNull);
    expect(auth.reads, 0);
  });

  test('a null or empty token sends the request without the header', () async {
    final (api, adapter) = _provider(auth: _Auth([null, '']));

    await api.send<Object?>(AgRequest(endpoint: _private));
    await api.send<Object?>(AgRequest(endpoint: _private));

    expect(adapter.sent.map(_authHeader), [null, null]);
  });

  test('a header the request sets itself is not overwritten', () async {
    final auth = _Auth(['t1']);
    final (api, adapter) = _provider(auth: auth);

    await api.send<Object?>(
      AgRequest(endpoint: _private, headers: {'authorization': 'Basic abc'}),
    );

    expect(adapter.sent.single['authorization'], 'Basic abc');
    expect(_authHeader(adapter.sent.single), isNull);
    expect(auth.reads, 0);
  });

  test('headerName and headerValue customise the header', () async {
    final (api, adapter) = _provider(auth: _ApiKeyAuth());

    await api.send<Object?>(AgRequest(endpoint: _private));

    expect(adapter.sent.single['X-Api-Key'], 'k1');
    expect(_authHeader(adapter.sent.single), isNull);
  });

  test('a failing readToken surfaces as AgApiException', () async {
    final (api, adapter) = _provider(auth: _BrokenAuth());

    await expectLater(
      api.send<Object?>(AgRequest(endpoint: _private)),
      throwsA(isA<AgApiException>()),
    );
    expect(adapter.sent, isEmpty);
  });

  test('a retried request re-reads the token', () async {
    final (api, adapter) = _provider(
      auth: _Auth(['t1', 't2']),
      statuses: [503, 200],
      retryPolicy: const AgRetryPolicy(maxAttempts: 1, backoff: Duration.zero),
    );

    await api.send<Object?>(AgRequest(endpoint: _private));

    expect(adapter.sent.map(_authHeader), ['Bearer t1', 'Bearer t2']);
  });
}
