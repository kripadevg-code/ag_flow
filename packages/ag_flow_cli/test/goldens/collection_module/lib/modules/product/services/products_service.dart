import 'package:ag_flow/ag_flow.dart';

/// Each mixin is a typed contract for one backend action, and this
/// Service lists only the actions its backend supports. The bodies below
/// are yours: a starting point written with `get` / `post` / `put` /
/// `delete`, so change any of them freely when the backend does something
/// unusual.
///
/// Replace `dynamic` with your real model type.
class ProductsService extends AgBaseService
    with
        AgListMixin<dynamic>,
        AgCreateMixin<dynamic>,
        AgUpdateMixin<dynamic, Object>,
        AgDestroyMixin<Object> {
  ProductsService(super.apiProvider);

  // TODO: point these at real endpoints declared in core/endpoints.dart.
  AgEndpoint get collectionEndpoint =>
      throw UnimplementedError('ProductsService.collectionEndpoint');

  AgEndpoint get resourceEndpoint =>
      throw UnimplementedError('ProductsService.resourceEndpoint');

  // TODO: replace `dynamic` with your model type, then decode/encode it.
  dynamic fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError('ProductsService.fromJson');

  Map<String, dynamic> toJson(dynamic item) =>
      throw UnimplementedError('ProductsService.toJson');

  @override
  Future<List<dynamic>> list() => get(
    collectionEndpoint,
    decode: (json) => [
      for (final item in json! as List<Object?>)
        fromJson(item! as Map<String, dynamic>),
    ],
  );

  @override
  Future<dynamic> create(dynamic item) => post(
    collectionEndpoint,
    body: toJson(item),
    decode: (json) => fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<dynamic> update(Object id, dynamic item) => put(
    resourceEndpoint,
    pathParams: {'id': id},
    body: toJson(item),
    decode: (json) => fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<void> destroy(Object id) =>
      delete(resourceEndpoint, pathParams: {'id': id});
}
