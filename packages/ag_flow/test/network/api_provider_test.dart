import 'dart:convert';
import 'dart:typed_data';

import 'package:ag_flow/ag_flow.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A hand-rolled fake transport: resolves synchronously with a canned
/// response, so tests never touch real sockets/timers (which
/// `flutter_test`'s strict binding correctly refuses to leave pending).
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => _handler(options);

  @override
  void close({bool force = false}) {}
}

ApiProvider _providerWith(
  ResponseBody Function(RequestOptions options) handler, {
  AgLogOptions logOptions = const AgLogOptions(),
}) {
  final provider = ApiProvider(
    baseUrl: 'https://api.test',
    logOptions: logOptions,
  );
  provider.debugDio.httpClientAdapter = _FakeHttpClientAdapter(handler);
  return provider;
}

ResponseBody _jsonResponse(Object? body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('ApiProvider.send', () {
    test(
      'decodes a successful response via the supplied decode callback',
      () async {
        final provider = _providerWith(
          (options) => _jsonResponse({'id': 1, 'name': 'Widget'}, 200),
        );

        final response = await provider.send<Map<String, dynamic>>(
          AgRequest(
            endpoint: const AgEndpoint('/products/{id}'),
            pathParams: {'id': 1},
          ),
          decode: (json) => json! as Map<String, dynamic>,
        );

        expect(response.statusCode, 200);
        expect(response.data, {'id': 1, 'name': 'Widget'});
      },
    );

    test(
      'surfaces a non-2xx response as AgApiException, never a raw DioException',
      () async {
        final provider = _providerWith(
          (options) => _jsonResponse({'error': 'not found'}, 404),
        );

        await expectLater(
          provider.send<dynamic>(
            AgRequest(endpoint: const AgEndpoint('/products/1')),
          ),
          throwsA(
            isA<AgApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              404,
            ),
          ),
        );
      },
    );

    test(
      'logs "[API] METHOD path Status: code Duration: Xms" for every request',
      () async {
        final logs = <String>[];
        final provider = _providerWith(
          (options) => _jsonResponse({'ok': true}, 200),
          logOptions: AgLogOptions(logger: logs.add),
        );

        await provider.send<dynamic>(
          AgRequest(endpoint: const AgEndpoint('/products')),
        );

        expect(
          logs.any(
            (line) => RegExp(
              r'^\[API\] GET /products Status: 200 Duration: \d+ms$',
            ).hasMatch(line),
          ),
          isTrue,
          reason: 'logs were: $logs',
        );
      },
    );

    test(
      'masks configured header keys in request logs, case-insensitively',
      () async {
        final logs = <String>[];
        final provider = _providerWith(
          (options) => _jsonResponse({'ok': true}, 200),
          logOptions: AgLogOptions(
            logger: logs.add,
            maskedHeaderKeys: const {'authorization'},
          ),
        );

        await provider.send<dynamic>(
          AgRequest(
            endpoint: const AgEndpoint('/products'),
            headers: const {
              'Authorization': 'Bearer secret-token',
              'X-Trace-Id': 'abc123',
            },
          ),
        );

        final requestLog = logs.firstWhere(
          (line) => line.startsWith('[API] →'),
        );
        expect(requestLog, isNot(contains('secret-token')));
        expect(requestLog, contains('***'));
        expect(
          requestLog,
          contains('abc123'),
          reason: 'only configured keys should be masked',
        );
      },
    );

    test(
      'masks configured body field keys in request logs when logRequestBody is enabled',
      () async {
        final logs = <String>[];
        final provider = _providerWith(
          (options) => _jsonResponse({'ok': true}, 200),
          logOptions: AgLogOptions(
            logger: logs.add,
            logRequestBody: true,
            maskedBodyKeys: const {'password'},
          ),
        );

        await provider.send<dynamic>(
          AgRequest(
            endpoint: const AgEndpoint('/login', methods: {AgHttpMethod.post}),
            body: {'username': 'jane', 'password': 'super-secret'},
          ),
        );

        final requestLog = logs.firstWhere(
          (line) => line.startsWith('[API] →'),
        );
        expect(requestLog, isNot(contains('super-secret')));
        expect(
          requestLog,
          contains('jane'),
          reason: 'only configured keys should be masked',
        );
      },
    );

    test('does not log request/response bodies by default', () async {
      final logs = <String>[];
      final provider = _providerWith(
        (options) => _jsonResponse({'password': 'super-secret'}, 200),
        logOptions: AgLogOptions(logger: logs.add),
      );

      await provider.send<dynamic>(
        AgRequest(
          endpoint: const AgEndpoint('/login', methods: {AgHttpMethod.post}),
          body: {'password': 'super-secret'},
        ),
      );

      expect(logs.any((line) => line.contains('super-secret')), isFalse);
    });

    test(
      'includes query parameters in the log line (ag_endpoint_rules.md §23)',
      () async {
        final logs = <String>[];
        final provider = _providerWith(
          (options) => _jsonResponse([], 200),
          logOptions: AgLogOptions(logger: logs.add),
        );

        await provider.send<dynamic>(
          AgRequest(
            endpoint: const AgEndpoint('/products'),
            queryParams: const {'page': 2, 'pageSize': 20},
          ),
        );

        expect(
          logs.any(
            (line) =>
                line.startsWith('[API] GET /products?') &&
                line.contains('page=2') &&
                line.contains('pageSize=20'),
          ),
          isTrue,
          reason: 'logs were: $logs',
        );
      },
    );

    test(
      'masks configured body keys at every nesting depth, not just the '
      'top level (ag_endpoint_rules.md §24)',
      () async {
        final logs = <String>[];
        final provider = _providerWith(
          (options) => _jsonResponse({'ok': true}, 200),
          logOptions: AgLogOptions(
            logger: logs.add,
            logRequestBody: true,
            maskedBodyKeys: const {'password'},
          ),
        );

        await provider.send<dynamic>(
          AgRequest(
            endpoint: const AgEndpoint('/login', methods: {AgHttpMethod.post}),
            body: {
              'user': {'name': 'jane', 'password': 'super-secret'},
              'accounts': [
                {'password': 'also-secret'},
              ],
            },
          ),
        );

        final requestLog = logs.firstWhere(
          (line) => line.startsWith('[API] →'),
        );
        expect(requestLog, isNot(contains('super-secret')));
        expect(requestLog, isNot(contains('also-secret')));
        expect(requestLog, contains('jane'));
      },
    );

    test(
      'a request whose endpoint has baseUrlOverride bypasses the '
      "provider's configured base URL entirely",
      () async {
        String? requestedUrl;
        final provider = _providerWith((options) {
          requestedUrl = options.uri.toString();
          return _jsonResponse({'ok': true}, 200);
        });

        await provider.send<dynamic>(
          AgRequest(
            endpoint: const AgEndpoint(
              '/legacy/products',
              baseUrlOverride: 'https://legacy.example.com',
            ),
          ),
        );

        expect(requestedUrl, 'https://legacy.example.com/legacy/products');
      },
    );

    test(
      'a pre-cancelled AgCancelToken aborts the request without leaking a '
      'raw dio type to the caller',
      () async {
        final provider = _providerWith((options) => _jsonResponse({}, 200));
        final token = AgCancelToken()..cancel('user navigated away');

        expect(token.isCancelled, isTrue);
        await expectLater(
          provider.send<dynamic>(
            AgRequest(endpoint: const AgEndpoint('/products')),
            cancelToken: token,
          ),
          throwsA(isA<AgApiException>()),
        );
      },
    );
  });
}
