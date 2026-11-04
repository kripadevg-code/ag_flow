import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ag_flow/ag_flow.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers 200 to `Bearer <valid>` and 401 to anything else.
class _Backend implements HttpClientAdapter {
  _Backend(this.valid);

  String valid;
  final List<String?> sent = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final header = options.headers['Authorization'] as String?;
    sent.add(header);
    // Let concurrent requests all reach the backend before any answer.
    await Future<void>.delayed(
      options.path.contains('slow') ? const Duration(milliseconds: 50) : Duration.zero,
    );
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      header == 'Bearer $valid' ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Auth extends AgAuth {
  _Auth({required this.token, this.next, this.refreshThrows = false});

  String? token;

  /// The token a refresh stores; `null` makes the refresh fail.
  final String? next;
  final bool refreshThrows;
  int refreshes = 0;
  int clears = 0;
  int logouts = 0;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<bool> refreshToken() async {
    refreshes++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (refreshThrows) throw StateError('refresh endpoint down');
    if (next == null) return false;
    token = next;
    return true;
  }

  @override
  void clearToken() {
    clears++;
    token = null;
  }

  @override
  void onLoggedOut() => logouts++;
}

(DioApiProvider, _Backend) _provider(_Auth auth, {String valid = 'new'}) {
  final provider = DioApiProvider(
    baseUrl: 'https://api.test',
    auth: auth,
    logOptions: const AgLogOptions(enabled: false),
  );
  final backend = _Backend(valid);
  provider.debugDio.httpClientAdapter = backend;
  return (provider, backend);
}

const _private = AgEndpoint('/me');

Future<AgResponse<Object?>> _send(ApiProvider api, [AgEndpoint endpoint = _private]) =>
    api.send<Object?>(AgRequest(endpoint: endpoint));

Matcher get _throws401 =>
    throwsA(isA<AgApiException>().having((e) => e.statusCode, 'statusCode', 401));

void main() {
  test('a 401 refreshes the token and sends the request again', () async {
    final auth = _Auth(token: 'old', next: 'new');
    final (api, backend) = _provider(auth);

    final response = await _send(api);

    expect(response.statusCode, 200);
    expect(auth.refreshes, 1);
    expect(backend.sent, ['Bearer old', 'Bearer new']);
  });

  test('requests that fail together share one refresh', () async {
    final auth = _Auth(token: 'old', next: 'new');
    final (api, backend) = _provider(auth);

    final responses = await Future.wait([_send(api), _send(api), _send(api)]);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(auth.refreshes, 1);
    expect(backend.sent.where((h) => h == 'Bearer new'), hasLength(3));
  });

  test('a 401 that arrives after the refresh finished reuses the new token', () async {
    final auth = _Auth(token: 'old', next: 'new');
    final (api, backend) = _provider(auth);

    // Both go out with the old token; the slow one's 401 arrives only after
    // the fast one's refresh is done.
    final responses = await Future.wait([
      _send(api, const AgEndpoint('/slow')),
      _send(api),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200]);
    expect(auth.refreshes, 1);
    expect(backend.sent.where((h) => h == 'Bearer old'), hasLength(2));
  });

  test('a failed refresh clears the token, logs out and fails with the 401', () async {
    final auth = _Auth(token: 'old')..logIn();
    final (api, _) = _provider(auth);

    await expectLater(_send(api), _throws401);

    expect(auth.refreshes, 1);
    expect(auth.clears, 1);
    expect(auth.logouts, 1);
    expect(auth.token, isNull);
    expect(auth.isLoggedIn, isFalse);
  });

  test('a refresh that throws counts as failed', () async {
    final auth = _Auth(token: 'old', refreshThrows: true);
    final (api, _) = _provider(auth);

    await expectLater(_send(api), _throws401);

    expect(auth.logouts, 1);
  });

  test('requests that fail together log out once', () async {
    final auth = _Auth(token: 'old');
    final (api, _) = _provider(auth);

    final results = await Future.wait([
      for (var i = 0; i < 3; i++) _send(api).then<Object?>((r) => r, onError: (Object e) => e),
    ]);

    expect(results, everyElement(isA<AgApiException>()));
    expect(auth.refreshes, 1);
    expect(auth.logouts, 1);
  });

  test('a request still 401 after the refresh is not sent a third time', () async {
    final auth = _Auth(token: 'old', next: 'new');
    final (api, backend) = _provider(auth, valid: 'never');

    await expectLater(_send(api), _throws401);

    expect(auth.refreshes, 1);
    expect(auth.logouts, 0);
    expect(backend.sent, ['Bearer old', 'Bearer new']);
  });

  test('a 401 on an auth: false endpoint does not refresh', () async {
    final auth = _Auth(token: 'old', next: 'new');
    final (api, _) = _provider(auth);

    await expectLater(
      _send(api, const AgEndpoint('/login', methods: {AgHttpMethod.post}, auth: false)),
      _throws401,
    );

    expect(auth.refreshes, 0);
  });

  test('a 401 on a request with its own header does not refresh', () async {
    final auth = _Auth(token: 'old', next: 'new');
    final (api, _) = _provider(auth);

    await expectLater(
      api.send<Object?>(
        AgRequest(endpoint: _private, headers: {'Authorization': 'Bearer custom'}),
      ),
      _throws401,
    );

    expect(auth.refreshes, 0);
  });

  test('a 401 sent without a token does not refresh', () async {
    final auth = _Auth(token: null, next: 'new');
    final (api, _) = _provider(auth);

    await expectLater(_send(api), _throws401);

    expect(auth.refreshes, 0);
    expect(auth.logouts, 0);
  });
}
