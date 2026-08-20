import 'dart:convert';
import 'dart:typed_data';

import 'package:ag_flow/ag_flow.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every request the fake transport receives, then resolves with a
/// canned response — same approach as `api_provider_test.dart`'s fake
/// adapter, so these tests never touch real sockets/timers.
class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this._handler);

  final List<RequestOptions> requests = [];
  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
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

abstract class _ProductEndpoints {
  static const collection = AgEndpoint(
    '/products',
    methods: {AgHttpMethod.get, AgHttpMethod.post},
  );
  static const item = AgEndpoint(
    '/products/{id}',
    methods: {AgHttpMethod.get, AgHttpMethod.put, AgHttpMethod.delete},
  );
}

class _ProductService extends AgBaseService
    with AgCrudService<Map<String, dynamic>, int> {
  _ProductService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => _ProductEndpoints.collection;

  @override
  AgEndpoint get resourceEndpoint => _ProductEndpoints.item;

  @override
  Map<String, dynamic> fromJson(Map<String, dynamic> json) => json;

  @override
  Map<String, dynamic> toJson(Map<String, dynamic> item) => item;
}

void main() {
  late _RecordingHttpClientAdapter adapter;
  late _ProductService service;

  void respondWith(ResponseBody Function(RequestOptions) handler) {
    adapter = _RecordingHttpClientAdapter(handler);
    final provider = ApiProvider(baseUrl: 'https://api.test');
    provider.debugDio.httpClientAdapter = adapter;
    service = _ProductService(provider);
  }

  group('AgCrudService', () {
    test(
      'getAll() hits the collection endpoint with no path parameter',
      () async {
        respondWith((_) => _jsonResponse([], 200));

        await service.getAll();

        expect(adapter.requests.single.path, '/products');
        expect(adapter.requests.single.method, 'GET');
      },
    );

    test('add() posts to the collection endpoint', () async {
      respondWith((_) => _jsonResponse({'id': 1, 'name': 'Widget'}, 200));

      final result = await service.add({'name': 'Widget'});

      expect(adapter.requests.single.path, '/products');
      expect(adapter.requests.single.method, 'POST');
      expect(result, {'id': 1, 'name': 'Widget'});
    });

    test(
      'getById() resolves the id into the resource endpoint, never the '
      'collection endpoint',
      () async {
        respondWith((_) => _jsonResponse({'id': 42, 'name': 'Widget'}, 200));

        await service.getById(42);

        expect(adapter.requests.single.path, '/products/42');
        expect(adapter.requests.single.method, 'GET');
      },
    );

    test(
      'update() PUTs to the resource endpoint with the id resolved',
      () async {
        respondWith((_) => _jsonResponse({'id': 7, 'name': 'Updated'}, 200));

        await service.update(7, {'name': 'Updated'});

        expect(adapter.requests.single.path, '/products/7');
        expect(adapter.requests.single.method, 'PUT');
      },
    );

    test(
      'delete() DELETEs the resource endpoint with the id resolved',
      () async {
        respondWith((_) => _jsonResponse(null, 204));

        await service.delete(9);

        expect(adapter.requests.single.path, '/products/9');
        expect(adapter.requests.single.method, 'DELETE');
      },
    );
  });
}
