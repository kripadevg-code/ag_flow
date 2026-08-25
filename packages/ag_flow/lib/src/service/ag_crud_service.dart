import 'package:ag_flow/src/network/ag_endpoint.dart';
import 'package:ag_flow/src/network/ag_http_method.dart';
import 'package:ag_flow/src/network/ag_request.dart';
import 'package:ag_flow/src/service/ag_base_service.dart';

/// Opt-in CRUD surface for [AgBaseService] subclasses whose resource maps
/// cleanly onto add/getAll/getById/update/delete against two related
/// endpoints: a collection endpoint (no path parameter, e.g. `/products`)
/// and an item endpoint (one `{id}` path parameter, e.g. `/products/{id}`).
///
/// These are deliberately two separate endpoints, not one shared between
/// them — `getAll`/`add` have no id to supply, so a single item-shaped
/// endpoint would either throw on every `getAll`/`add` call (missing
/// `{id}`) or, pointed at the collection shape instead, silently ignore
/// the id on every `getById`/`update`/`delete` call instead of ever
/// reaching the right URL. See `AgPathResolver.resolve`: it only checks
/// that every `{token}` *in the template* has a value, never that a
/// supplied value corresponds to a token that actually exists in it.
///
/// Applying this mixin never prevents adding feature-specific methods
/// (`searchProduct()`, `filterProducts()`, ...) alongside the CRUD ones —
/// AG must not restrict those.
mixin AgCrudService<T, ID extends Object> on AgBaseService {
  /// The resource's collection endpoint, e.g. `/products` — no path
  /// parameters. Used by [getAll] and [add].
  AgEndpoint get collectionEndpoint;

  /// The resource's item endpoint, e.g. `/products/{id}` — must have
  /// exactly one path parameter named `id`. Used by [getById], [update],
  /// and [delete].
  AgEndpoint get resourceEndpoint;

  /// Decodes a single item from its JSON representation.
  T fromJson(Map<String, dynamic> json);

  /// Encodes a single item to its JSON representation.
  Map<String, dynamic> toJson(T item);

  Future<T> add(T item) async {
    return fetchItem(
      AgRequest(
        endpoint: collectionEndpoint,
        method: AgHttpMethod.post,
        body: toJson(item),
      ),
      fromJson,
    );
  }

  Future<List<T>> getAll({Map<String, dynamic>? queryParams}) async {
    return fetchList(
      AgRequest(
        endpoint: collectionEndpoint,
        queryParams: queryParams ?? const {},
      ),
      fromJson,
    );
  }

  Future<T> getById(ID id) async {
    return fetchItem(
      AgRequest(endpoint: resourceEndpoint, pathParams: {'id': id}),
      fromJson,
    );
  }

  Future<T> update(ID id, T item) async {
    return fetchItem(
      AgRequest(
        endpoint: resourceEndpoint,
        method: AgHttpMethod.put,
        pathParams: {'id': id},
        body: toJson(item),
      ),
      fromJson,
    );
  }

  Future<void> delete(ID id) async {
    await send<dynamic>(
      AgRequest(
        endpoint: resourceEndpoint,
        method: AgHttpMethod.delete,
        pathParams: {'id': id},
      ),
    );
  }
}
