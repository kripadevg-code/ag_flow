import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/core/arguments/arguments.dart';

/// Declarative by design — this Service contains no request plumbing.
///
/// Everything that differs between backends is a *value* you declare:
/// [envelope] says where the payload sits inside a response body, and the
/// endpoints say where to find the resource. AG owns the requests and the
/// decoding, so this file reads the same in every module of every app.
{{^has_model}}///
/// Replace `dynamic` with your real model type.
{{/has_model}}class {{module_class_prefix}}Service extends AgBaseService
    with AgCrudService<{{model_class}}, {{id_type}}> {
  {{module_class_prefix}}Service(super.apiProvider);

  // TODO: point these at real endpoints declared in core/endpoints.dart.
  @override
  AgEndpoint get collectionEndpoint =>
      throw UnimplementedError('{{module_class_prefix}}Service.collectionEndpoint');

  @override
  AgEndpoint get resourceEndpoint =>
      throw UnimplementedError('{{module_class_prefix}}Service.resourceEndpoint');

  /// Where the payload sits in a response body. Delete this override if
  /// the body *is* the payload; use `AgEnvelope.key('data')` for
  /// `{"data": {...}}`, or `AgEnvelope.path([...])` when it's nested.
  @override
  AgEnvelope get envelope => AgEnvelope.raw;

{{#has_model}}  @override
  {{model_class}} fromJson(Map<String, dynamic> json) =>
      {{model_class}}.fromJson(json);

  @override
  Map<String, dynamic> toJson({{model_class}} item) => item.toJson();
{{/has_model}}{{^has_model}}  // TODO: replace `dynamic` with your model type, then decode/encode it.
  @override
  dynamic fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError('{{module_class_prefix}}Service.fromJson');

  @override
  Map<String, dynamic> toJson(dynamic item) =>
      throw UnimplementedError('{{module_class_prefix}}Service.toJson');
{{/has_model}}

  /// The one genuinely app-specific decision in this file: which field of
  /// the navigation argument identifies this resource. Everything below
  /// is a one-line adapter over the inherited CRUD methods.
  {{id_type}} idOf({{module_class_prefix}}PageArgument argument) =>
      {{{id_of_expression}}};

  Future<{{model_class}}> getByArgument({{module_class_prefix}}PageArgument argument) =>
      getById(idOf(argument));
{{#generate_update}}

  Future<{{model_class}}> updateByArgument(
    {{module_class_prefix}}PageArgument argument,
    {{model_class}} item,
  ) => update(idOf(argument), item);
{{/generate_update}}
{{#generate_delete}}

  Future<void> deleteByArgument({{module_class_prefix}}PageArgument argument) =>
      delete(idOf(argument));
{{/generate_delete}}
}
