import 'package:ag_flow/ag_flow.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records `METHOD path?query` for every request and echoes a canned body.
class _Api implements ApiProvider {
  final List<String> calls = [];

  @override
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
    AgCancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final path = request.resolvePath();
    final query = request.queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    calls.add('${request.method.name} $path${query.isEmpty ? '' : '?$query'}');
    final json =
        request.method == AgHttpMethod.get && !path.contains(RegExp(r'/\d'))
        ? [
            {'id': 1},
          ]
        : {'id': 1};
    return AgResponse<D>(
      statusCode: 200,
      data: decode != null ? decode(json) : json as D,
      headers: const {},
      duration: Duration.zero,
    );
  }
}

typedef _M = Map<String, dynamic>;

const Set<AgHttpMethod> _all = {
  AgHttpMethod.get,
  AgHttpMethod.post,
  AgHttpMethod.put,
  AgHttpMethod.delete,
};
const _collection = AgEndpoint('/items', methods: _all);
const _resource = AgEndpoint('/items/{id}', methods: _all);

List<_M> _many(Object? json) => (json! as List).cast<_M>();
_M _one(Object? json) => json! as _M;

/// All five contracts, each body written by the Service itself — the mixins
/// only fix the method names and types.
class _ItemsService extends AgBaseService
    with
        AgListMixin<_M>,
        AgCreateMixin<_M>,
        AgRetrieveMixin<_M, int>,
        AgUpdateMixin<_M, int>,
        AgDestroyMixin<int> {
  _ItemsService(super.apiProvider);

  @override
  Future<List<_M>> list() async =>
      (await send(AgRequest(endpoint: _collection), decode: _many)).data;

  @override
  Future<_M> create(_M item) async => (await send(
    AgRequest(endpoint: _collection, method: AgHttpMethod.post, body: item),
    decode: _one,
  )).data;

  @override
  Future<_M> retrieve(int id) async => (await send(
    AgRequest(endpoint: _resource, pathParams: {'id': id}),
    decode: _one,
  )).data;

  @override
  Future<_M> update(int id, _M item) async => (await send(
    AgRequest(
      endpoint: _resource,
      method: AgHttpMethod.put,
      pathParams: {'id': id},
      body: item,
    ),
    decode: _one,
  )).data;

  @override
  Future<void> destroy(int id) => send<void>(
    AgRequest(
      endpoint: _resource,
      method: AgHttpMethod.delete,
      pathParams: {'id': id},
    ),
  );

  /// A feature method — an ordinary method, no contract needed.
  Future<List<_M>> search(String term) async => (await send(
    AgRequest(endpoint: _collection, queryParams: {'q': term}),
    decode: _many,
  )).data;
}

/// A composite lookup — the contract's `ID` is any type, the Service maps
/// it onto the URL however its backend wants.
class _OrgItemsService extends AgBaseService
    with AgRetrieveMixin<_M, ({String org, int id})> {
  _OrgItemsService(super.apiProvider);

  @override
  Future<_M> retrieve(({String org, int id}) key) async => (await send(
    AgRequest(
      endpoint: const AgEndpoint('/orgs/{org}/items/{id}'),
      pathParams: {'org': key.org, 'id': key.id},
    ),
    decode: _one,
  )).data;
}

/// Paging is one opt-in line; the override adds an optional parameter and
/// still satisfies `AgListMixin`.
class _PagedItemsService extends AgBaseService with AgListMixin<_M> {
  _PagedItemsService(super.apiProvider, this.pagination);

  @override
  final AgPagination pagination;

  @override
  Future<List<_M>> list({int page = 1}) async => (await send(
    AgRequest(endpoint: _collection, queryParams: pagination.query(page)),
    decode: _many,
  )).data;
}

void main() {
  late _Api api;
  setUp(() => api = _Api());

  test('a Service implements each mixed-in contract itself', () async {
    final service = _ItemsService(api);

    expect(await service.list(), hasLength(1));
    expect((await service.create({}))['id'], 1);
    expect((await service.retrieve(2))['id'], 1);
    expect((await service.update(3, {}))['id'], 1);
    await service.destroy(4);
    expect(await service.search('x'), hasLength(1));

    expect(api.calls, [
      'GET /items',
      'POST /items',
      'GET /items/2',
      'PUT /items/3',
      'DELETE /items/4',
      'GET /items?q=x',
    ]);
  });

  test('the lookup type is free — a record maps onto its own URL', () async {
    await _OrgItemsService(api).retrieve((org: 'acme', id: 9));

    expect(api.calls, ['GET /orgs/acme/items/9']);
  });

  test('pagination is off unless a Service opts in', () {
    expect(_ItemsService(api).pagination, isNull);
  });

  test('AgPageNumberPagination names its parameters', () async {
    final service = _PagedItemsService(
      api,
      const AgPageNumberPagination(
        pageSize: 10,
        pageParam: '_page',
        sizeParam: '_limit',
      ),
    );

    await service.list();
    await service.list(page: 3);

    expect(api.calls, [
      'GET /items?_page=1&_limit=10',
      'GET /items?_page=3&_limit=10',
    ]);
  });

  test('AgLimitOffsetPagination skips the earlier pages', () async {
    final service = _PagedItemsService(
      api,
      const AgLimitOffsetPagination(),
    );

    await service.list(page: 3);

    expect(api.calls, ['GET /items?offset=40&limit=20']);
  });

  test('a short page is the last page', () {
    const pagination = AgPageNumberPagination(pageSize: 2);

    expect(pagination.isLastPage([1, 2]), isFalse);
    expect(pagination.isLastPage([1]), isTrue);
  });

  test('ApiProvider(...) still builds the dio default', () {
    expect(ApiProvider(baseUrl: 'https://x.test'), isA<DioApiProvider>());
  });
}
