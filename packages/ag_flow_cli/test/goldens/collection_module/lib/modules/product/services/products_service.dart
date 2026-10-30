import 'package:ag_flow/ag_flow.dart';

/// Each mixin is a typed contract for one backend action, and this
/// Service lists only the actions its backend supports. The bodies below
/// are yours: a starting point written with `send`, so change any of them
/// freely when the backend does something unusual.
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
  Future<List<dynamic>> list() async {
    final response = await send<List<dynamic>>(
      AgRequest(endpoint: collectionEndpoint),
      decode: (json) => [
        for (final item in json! as List<Object?>)
          fromJson(item! as Map<String, dynamic>),
      ],
    );
    return response.data;
  }

  @override
  Future<dynamic> create(dynamic item) async {
    final response = await send<dynamic>(
      AgRequest(
        endpoint: collectionEndpoint,
        method: AgHttpMethod.post,
        body: toJson(item),
      ),
      decode: (json) => fromJson(json! as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<dynamic> update(Object id, dynamic item) async {
    final response = await send<dynamic>(
      AgRequest(
        endpoint: resourceEndpoint,
        method: AgHttpMethod.put,
        pathParams: {'id': id},
        body: toJson(item),
      ),
      decode: (json) => fromJson(json! as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<void> destroy(Object id) async {
    await send<void>(
      AgRequest(
        endpoint: resourceEndpoint,
        method: AgHttpMethod.delete,
        pathParams: {'id': id},
      ),
    );
  }
}
