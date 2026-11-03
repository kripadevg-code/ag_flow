import 'dart:typed_data';

import 'package:ag_flow/ag_flow.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each attempt with the next status in [statuses], recording the
/// method of every request that reached the transport.
class _Transport implements HttpClientAdapter {
  _Transport(this.statuses);

  final List<int> statuses;
  final List<String> methods = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    methods.add(options.method);
    return ResponseBody.fromString('{}', statuses[methods.length - 1]);
  }

  @override
  void close({bool force = false}) {}
}

(DioApiProvider, _Transport) _provider(
  List<int> statuses, {
  AgRetryPolicy policy = const AgRetryPolicy(backoff: Duration.zero),
}) {
  final provider = DioApiProvider(baseUrl: 'https://api.test', retryPolicy: policy);
  final transport = _Transport(statuses);
  provider.debugDio.httpClientAdapter = transport;
  return (provider, transport);
}

AgRequest _request(AgHttpMethod method) => AgRequest(
  endpoint: const AgEndpoint('/orders', methods: {AgHttpMethod.get, AgHttpMethod.post}),
  method: method,
);

void main() {
  test('a GET that hits a 503 is retried until it succeeds', () async {
    final (provider, transport) = _provider([503, 503, 200]);

    final response = await provider.send<Object?>(_request(AgHttpMethod.get));

    expect(response.statusCode, 200);
    expect(transport.methods, ['GET', 'GET', 'GET']);
  });

  test('retries stop after maxAttempts and surface the last error', () async {
    final (provider, transport) = _provider([503, 503, 503, 503]);

    await expectLater(
      provider.send<Object?>(_request(AgHttpMethod.get)),
      throwsA(isA<AgApiException>().having((e) => e.statusCode, 'statusCode', 503)),
    );
    expect(transport.methods, hasLength(4), reason: 'one try plus 3 retries');
  });

  test('a POST is never retried by default — it may already be applied', () async {
    final (provider, transport) = _provider([504, 200]);

    await expectLater(
      provider.send<Object?>(_request(AgHttpMethod.post)),
      throwsA(isA<AgApiException>()),
    );
    expect(transport.methods, ['POST']);
  });

  test('a POST is retried when the policy opts it in', () async {
    final (provider, transport) = _provider(
      [504, 200],
      policy: const AgRetryPolicy(backoff: Duration.zero, retryableMethods: {'POST'}),
    );

    final response = await provider.send<Object?>(_request(AgHttpMethod.post));

    expect(response.statusCode, 200);
    expect(transport.methods, ['POST', 'POST']);
  });

  test('a status outside retryableStatusCodes is not retried', () async {
    final (provider, transport) = _provider([500, 200]);

    await expectLater(
      provider.send<Object?>(_request(AgHttpMethod.get)),
      throwsA(isA<AgApiException>()),
    );
    expect(transport.methods, ['GET']);
  });
}
