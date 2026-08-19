import 'package:ag_flow/src/network/ag_endpoint.dart';
import 'package:ag_flow/src/network/ag_http_method.dart';
import 'package:ag_flow/src/network/ag_request.dart';
import 'package:ag_flow/src/service/ag_base_service.dart';

/// Opt-in CRUD surface for [AgBaseService] subclasses whose resource maps
/// cleanly onto add/getAll/getById/update/delete against a single
/// `{id}`-keyed [resourceEndpoint].
///
/// Applying this mixin never prevents adding feature-specific methods
/// (`searchProduct()`, `filterProducts()`, ...) alongside the CRUD ones —
/// AG must not restrict those.
mixin AgCrudService<T, ID extends Object> on AgBaseService {
  /// The endpoint representing this resource's collection/item routes.
  /// Its path template's id path parameter must be named `id`
  /// (`/products/{id}`).
  AgEndpoint get resourceEndpoint;

  /// Decodes a single item from its JSON representation.
  T fromJson(Map<String, dynamic> json);

  /// Encodes a single item to its JSON representation.
  Map<String, dynamic> toJson(T item);

  Future<T> add(T item) async {
    final response = await send<Map<String, dynamic>>(
      AgRequest(
        endpoint: resourceEndpoint,
        method: AgHttpMethod.post,
        body: toJson(item),
      ),
      decode: (json) => json! as Map<String, dynamic>,
    );
    return fromJson(response.data);
  }

  Future<List<T>> getAll({Map<String, dynamic>? queryParams}) async {
    final response = await send<List<dynamic>>(
      AgRequest(
        endpoint: resourceEndpoint,
        queryParams: queryParams ?? const {},
      ),
      decode: (json) => json! as List<dynamic>,
    );
    return response.data.cast<Map<String, dynamic>>().map(fromJson).toList();
  }

  Future<T> getById(ID id) async {
    final response = await send<Map<String, dynamic>>(
      AgRequest(endpoint: resourceEndpoint, pathParams: {'id': id}),
      decode: (json) => json! as Map<String, dynamic>,
    );
    return fromJson(response.data);
  }

  Future<T> update(ID id, T item) async {
    final response = await send<Map<String, dynamic>>(
      AgRequest(
        endpoint: resourceEndpoint,
        method: AgHttpMethod.put,
        pathParams: {'id': id},
        body: toJson(item),
      ),
      decode: (json) => json! as Map<String, dynamic>,
    );
    return fromJson(response.data);
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
