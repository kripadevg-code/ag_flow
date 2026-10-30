import 'package:ag_flow/ag_flow.dart';

/// Each mixin is a typed contract for one backend action, and this
/// Service lists only the actions its backend supports. The bodies below
/// are yours: a starting point written with `get` / `put` / `delete`, so
/// change any of them freely when the backend does something unusual.
///
/// Replace `dynamic` with your real model type.
class ProductDetailsService extends AgBaseService
    with AgRetrieveMixin<dynamic, Object>, AgUpdateMixin<dynamic, Object>, AgDestroyMixin<Object> {
  ProductDetailsService(super.apiProvider);

  // TODO: point this at a real endpoint declared in core/endpoints.dart.
  AgEndpoint get resourceEndpoint =>
      throw UnimplementedError('ProductDetailsService.resourceEndpoint');

  // TODO: replace `dynamic` with your model type, then decode/encode it.
  dynamic fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError('ProductDetailsService.fromJson');

  Map<String, dynamic> toJson(dynamic item) =>
      throw UnimplementedError('ProductDetailsService.toJson');

  @override
  Future<dynamic> retrieve(Object id) => get(
    resourceEndpoint,
    pathParams: {'id': id},
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
  Future<void> destroy(Object id) => delete(resourceEndpoint, pathParams: {'id': id});
}
