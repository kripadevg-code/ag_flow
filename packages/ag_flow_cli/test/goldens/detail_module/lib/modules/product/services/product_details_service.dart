import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/core/arguments/arguments.dart';

/// Declarative by design — this Service contains no request plumbing.
///
/// Everything that differs between backends is a *value* you declare:
/// [envelope] says where the payload sits inside a response body, and the
/// endpoints say where to find the resource. AG owns the requests and the
/// decoding, so this file reads the same in every module of every app.
///
/// Replace `dynamic` with your real model type.
class ProductDetailsService extends AgBaseService
    with AgCrudService<dynamic, Object> {
  ProductDetailsService(super.apiProvider);

  // TODO: point these at real endpoints declared in core/endpoints.dart.
  @override
  AgEndpoint get collectionEndpoint =>
      throw UnimplementedError('ProductDetailsService.collectionEndpoint');

  @override
  AgEndpoint get resourceEndpoint =>
      throw UnimplementedError('ProductDetailsService.resourceEndpoint');

  /// Where the payload sits in a response body. Delete this override if
  /// the body *is* the payload; use `AgEnvelope.key('data')` for
  /// `{"data": {...}}`, or `AgEnvelope.path([...])` when it's nested.
  @override
  AgEnvelope get envelope => AgEnvelope.raw;

  // TODO: replace `dynamic` with your model type, then decode/encode it.
  @override
  dynamic fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError('ProductDetailsService.fromJson');

  @override
  Map<String, dynamic> toJson(dynamic item) =>
      throw UnimplementedError('ProductDetailsService.toJson');

  /// The one genuinely app-specific decision in this file: which field of
  /// the navigation argument identifies this resource. Everything below
  /// is a one-line adapter over the inherited CRUD methods.
  Object idOf(ProductDetailsPageArgument argument) => throw UnimplementedError(
    'ProductDetailsService.idOf — return the id field from the argument.',
  );

  Future<dynamic> getByArgument(ProductDetailsPageArgument argument) =>
      getById(idOf(argument));

  Future<dynamic> updateByArgument(
    ProductDetailsPageArgument argument,
    dynamic item,
  ) => update(idOf(argument), item);

  Future<void> deleteByArgument(ProductDetailsPageArgument argument) =>
      delete(idOf(argument));
}
