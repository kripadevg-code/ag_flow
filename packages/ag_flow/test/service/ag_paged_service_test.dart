import 'dart:convert';
import 'dart:typed_data';

import 'package:ag_flow/ag_flow.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// The point of `AgPageStrategy` + `AgEnvelope` is that four genuinely
/// different backend dialects all produce the *same* declarative Service
/// — no imperative query-param building, decoding, or `hasMore`
/// arithmetic anywhere in feature code. These tests hold that line: every
/// Service below is pure declaration, and the differences between the
/// backends live entirely in the two values each one declares.
class _Item {
  const _Item(this.id);
  factory _Item.fromJson(Map<String, dynamic> json) => _Item(json['id'] as int);
  final int id;
}

/// Records every request so the query parameters a strategy produced can
/// be asserted, and replays a canned body.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.bodyFor);

  final String Function(RequestOptions options) bodyFor;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      bodyFor(options),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiProvider _provider(_FakeAdapter adapter) {
  final provider = ApiProvider(
    baseUrl: 'https://api.test',
    logOptions: const AgLogOptions(enabled: false),
  );
  provider.debugDio.httpClientAdapter = adapter;
  return provider;
}

const _collection = AgEndpoint('/items');

/// Backend A: page numbers, bare array — `?page=1&limit=2` -> `[...]`
class _PageNumberService extends AgBaseService with AgPagedService<_Item, int> {
  const _PageNumberService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => _collection;
  @override
  _Item fromJson(Map<String, dynamic> json) => _Item.fromJson(json);
  @override
  AgPageStrategy<int> get pageStrategy =>
      const AgPageNumberStrategy(pageSize: 2);
}

/// Backend B: offset/limit, payload wrapped in `{"data": [...]}`
class _OffsetEnvelopedService extends AgBaseService
    with AgPagedService<_Item, int> {
  const _OffsetEnvelopedService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => _collection;
  @override
  _Item fromJson(Map<String, dynamic> json) => _Item.fromJson(json);
  @override
  AgEnvelope get envelope => const AgEnvelope.key('data');
  @override
  AgPageStrategy<int> get pageStrategy => const AgOffsetStrategy(pageSize: 2);
}

/// Backend C: opaque cursor beside the payload —
/// `{"results": [...], "nextCursor": "abc"}`
class _CursorService extends AgBaseService with AgPagedService<_Item, String> {
  const _CursorService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => _collection;
  @override
  _Item fromJson(Map<String, dynamic> json) => _Item.fromJson(json);
  @override
  AgEnvelope get envelope => const AgEnvelope.key('results');
  @override
  AgPageStrategy<String> get pageStrategy =>
      const AgCursorStrategy(nextTokenKey: 'nextCursor');
}

/// Backend D: doesn't paginate at all — one response, whole collection.
class _SinglePageService extends AgBaseService with AgPagedService<_Item, int> {
  const _SinglePageService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => _collection;
  @override
  _Item fromJson(Map<String, dynamic> json) => _Item.fromJson(json);
  @override
  AgPageStrategy<int> get pageStrategy => const AgSinglePageStrategy();
}

/// Backend E: nested payload plus an app-wide filter on every request.
class _FilteredService extends AgBaseService with AgPagedService<_Item, int> {
  const _FilteredService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => _collection;
  @override
  _Item fromJson(Map<String, dynamic> json) => _Item.fromJson(json);
  @override
  AgEnvelope get envelope => const AgEnvelope.path(['response', 'items']);
  @override
  Map<String, dynamic> get pageQueryParams => const {'category': 'books'};
  @override
  AgPageStrategy<int> get pageStrategy =>
      const AgPageNumberStrategy(pageSize: 2);
}

void main() {
  group('page-number backend, bare array', () {
    test(
      'sends the strategy query params and reports a further page',
      () async {
        final adapter = _FakeAdapter(
          (_) => jsonEncode([
            {'id': 1},
            {'id': 2},
          ]),
        );
        final service = _PageNumberService(_provider(adapter));

        final page = await service.getPage(1);

        expect(adapter.requests.single.queryParameters, {
          'page': '1',
          'limit': '2',
        });
        expect(page.items.map((i) => i.id), [1, 2]);
        expect(
          page.hasMore,
          isTrue,
          reason: 'a full page means more may exist',
        );
        expect(page.nextPageKey, 2);
      },
    );

    test('a short page ends pagination', () async {
      final adapter = _FakeAdapter(
        (_) => jsonEncode([
          {'id': 9},
        ]),
      );
      final service = _PageNumberService(_provider(adapter));

      final page = await service.getPage(3);

      expect(page.hasMore, isFalse);
      expect(page.nextPageKey, isNull);
    });
  });

  test(
    'offset backend advances by page size and unwraps {"data": [...]}',
    () async {
      final adapter = _FakeAdapter(
        (_) => jsonEncode({
          'data': [
            {'id': 5},
            {'id': 6},
          ],
        }),
      );
      final service = _OffsetEnvelopedService(_provider(adapter));

      final page = await service.getPage(4);

      expect(adapter.requests.single.queryParameters, {
        'offset': '4',
        'limit': '2',
      });
      expect(page.items.map((i) => i.id), [5, 6]);
      expect(page.nextPageKey, 6, reason: 'offset advances by pageSize');
    },
  );

  group('cursor backend', () {
    test(
      'sends no cursor param for the first page, then follows the token',
      () async {
        final adapter = _FakeAdapter(
          (_) => jsonEncode({
            'results': [
              {'id': 1},
            ],
            'nextCursor': 'abc',
          }),
        );
        final service = _CursorService(_provider(adapter));

        final first = await service.getPage(
          service.pageStrategy.initialPageKey,
        );

        expect(
          adapter.requests.single.queryParameters,
          isEmpty,
          reason: 'the first page carries no cursor',
        );
        expect(first.hasMore, isTrue);
        expect(first.nextPageKey, 'abc');

        await service.getPage('abc');
        expect(adapter.requests.last.queryParameters, {'cursor': 'abc'});
      },
    );

    test('a missing next token ends pagination even on a full page', () async {
      final adapter = _FakeAdapter(
        (_) => jsonEncode({
          'results': [
            {'id': 1},
            {'id': 2},
          ],
        }),
      );
      final service = _CursorService(_provider(adapter));

      final page = await service.getPage('');

      expect(page.items, hasLength(2));
      expect(page.hasMore, isFalse);
      expect(page.nextPageKey, isNull);
    });
  });

  test(
    'a non-paginating backend sends no paging params and never asks again',
    () async {
      final adapter = _FakeAdapter(
        (_) => jsonEncode([
          {'id': 1},
          {'id': 2},
          {'id': 3},
        ]),
      );
      final service = _SinglePageService(_provider(adapter));

      final page = await service.getPage(1);

      expect(adapter.requests.single.queryParameters, isEmpty);
      expect(page.items, hasLength(3));
      expect(page.hasMore, isFalse);
    },
  );

  test(
    'pageQueryParams merge with the strategy params, nested payload',
    () async {
      final adapter = _FakeAdapter(
        (_) => jsonEncode({
          'response': {
            'items': [
              {'id': 7},
            ],
          },
        }),
      );
      final service = _FilteredService(_provider(adapter));

      final page = await service.getPage(1);

      expect(adapter.requests.single.queryParameters, {
        'category': 'books',
        'page': '1',
        'limit': '2',
      });
      expect(page.items.single.id, 7);
    },
  );

  test(
    'a mismatched envelope fails with a named, actionable error rather '
    'than an opaque cast failure',
    () async {
      final adapter = _FakeAdapter(
        (_) => jsonEncode({'data': <Object?>[]}),
      );
      // Declares `raw`, but the backend wraps — the exact mistake this
      // error message exists to explain.
      final service = _PageNumberService(_provider(adapter));

      await expectLater(
        service.getPage(1),
        throwsA(
          isA<AgEnvelopeException>().having(
            (e) => e.message,
            'message',
            contains('envelope'),
          ),
        ),
      );
    },
  );
}
