import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow/testing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = AgEndpoint('/items', methods: {AgHttpMethod.get, AgHttpMethod.post});
const _item = AgEndpoint('/items/{id}');

class _Item {
  const _Item(this.id);

  factory _Item.fromJson(Map<String, dynamic> json) => _Item(json['id'] as int);

  final int id;
}

class _ItemsService extends AgBaseService {
  _ItemsService(super.apiProvider);

  Future<List<_Item>> list({int page = 1}) => get(
    _items,
    queryParams: {'page': page},
    decode: (json) => [
      for (final item in json! as List<Object?>) _Item.fromJson(item! as Map<String, dynamic>),
    ],
  );

  Future<_Item> retrieve(int id) => get(
    _item,
    pathParams: {'id': id},
    decode: (json) => _Item.fromJson(json! as Map<String, dynamic>),
  );

  Future<Object?> create(Map<String, Object?> body) => post(_items, body: body);
}

class _Controller extends ChangeNotifier {}

void main() {
  late AgFakeApiProvider api;
  late _ItemsService service;

  setUp(() {
    api = AgFakeApiProvider();
    service = _ItemsService(api);
  });

  group('AgFakeApiProvider', () {
    test('answers with the reply, decoded by the Service', () async {
      api.reply(
        _items,
        json: [
          {'id': 1},
          {'id': 2},
        ],
      );

      final items = await service.list();

      expect(items.map((i) => i.id), [1, 2]);
    });

    test('records every request with its path and query parameters', () async {
      api.reply(_items, json: <Object?>[]);

      await service.list(page: 3);

      expect(api.requests, hasLength(1));
      expect(api.requests.single.method.name, 'GET');
      expect(api.requests.single.queryParams, {'page': 3});
    });

    test('one reply covers every path parameter of an endpoint', () async {
      api.replyWith(_item, (request) => {'id': request.pathParams['id']});

      expect((await service.retrieve(7)).id, 7);
      expect((await service.retrieve(9)).id, 9);
    });

    test('matches on the HTTP method, not just the endpoint', () async {
      api
        ..reply(_items, json: <Object?>[])
        ..replyWith(_items, (request) => request.body, method: AgHttpMethod.post);

      expect(await service.create({'name': 'new'}), {'name': 'new'});
      expect(await service.list(), isEmpty);
    });

    test('the latest reply for an endpoint wins', () async {
      api
        ..reply(_items, json: <Object?>[])
        ..reply(
          _items,
          json: [
            {'id': 5},
          ],
        );

      expect((await service.list()).single.id, 5);
    });

    test('fail throws the given AgApiException', () async {
      const offline = AgApiException(message: 'offline', type: AgApiErrorType.connection);
      api.fail(_items, offline);

      await expectLater(service.list(), throwsA(same(offline)));
      expect(api.requests, hasLength(1));
    });

    test('a request with no reply throws a StateError naming it', () async {
      await expectLater(
        service.retrieve(1),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('GET /items/{id}')),
        ),
      );
    });

    test('drives a Repo through guard like the real provider', () async {
      api.fail(
        _items,
        const AgApiException(message: 'offline', type: AgApiErrorType.connection),
      );
      final repo = _ItemsRepo(service);

      await expectLater(
        repo.list(),
        throwsA(
          isA<AgRepoException>().having((e) => e.kind, 'kind', AgRepoErrorKind.network),
        ),
      );
    });
  });

  group('resetAgFlow', () {
    test('clears registrations, live bindings and route data', () {
      final controller = _Controller();
      AgLocator.put<_Controller>(controller);
      AgRouteData.pathParameters = {'id': '1'};

      resetAgFlow();

      expect(AgLocator.find<_Controller>, throwsStateError);
      expect(AgRouteData.pathParameters, isEmpty);
      // A realized ChangeNotifier is disposed, so its listeners don't leak.
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });
  });
}

class _ItemsRepo extends AgBaseRepo {
  const _ItemsRepo(this._service);

  final _ItemsService _service;

  Future<List<_Item>> list() => guard(_service.list);
}
