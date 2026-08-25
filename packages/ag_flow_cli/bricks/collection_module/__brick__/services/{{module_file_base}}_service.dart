import 'package:ag_flow/ag_flow.dart';

/// Declarative by design — this Service contains no request plumbing.
///
/// Everything that differs between backends is a *value* you declare:
/// [pageStrategy] (the paging dialect) and [envelope] (where the payload
/// sits inside a response body). AG owns the requests, the decoding, and
/// the paging arithmetic — so this file reads the same in every module of
/// every app, no matter how unusual the API behind it is.
///
/// Replace `dynamic` with your real model type.
class {{module_class_prefix}}Service extends AgBaseService
    with AgCrudService<dynamic, Object>, AgPagedService<dynamic, int> {
  {{module_class_prefix}}Service(super.apiProvider);

  // TODO: point these at real endpoints declared in core/endpoints.dart.
  @override
  AgEndpoint get collectionEndpoint =>
      throw UnimplementedError('{{module_class_prefix}}Service.collectionEndpoint');

  @override
  AgEndpoint get resourceEndpoint =>
      throw UnimplementedError('{{module_class_prefix}}Service.resourceEndpoint');

  /// How this backend paginates. Swap in [AgOffsetStrategy],
  /// [AgCursorStrategy], or [AgSinglePageStrategy] (for a backend that
  /// returns the whole collection in one response) to match yours.
  @override
  AgPageStrategy<int> get pageStrategy => const AgPageNumberStrategy();

  /// Where the payload sits in a response body. Delete this override if
  /// the body *is* the payload; use `AgEnvelope.key('data')` for
  /// `{"data": [...]}`, or `AgEnvelope.path([...])` when it's nested.
  @override
  AgEnvelope get envelope => AgEnvelope.raw;

  // TODO: replace `dynamic` with your model type, then decode/encode it.
  @override
  dynamic fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError('{{module_class_prefix}}Service.fromJson');

  @override
  Map<String, dynamic> toJson(dynamic item) =>
      throw UnimplementedError('{{module_class_prefix}}Service.toJson');
}
