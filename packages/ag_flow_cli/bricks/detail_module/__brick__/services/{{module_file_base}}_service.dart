import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}
/// Each mixin is a typed contract for one backend action, and this
/// Service lists only the actions its backend supports. The bodies below
/// are yours: a starting point written with `get` / `put` / `delete`, so
/// change any of them freely when the backend does something unusual.
{{^has_model}}///
/// Replace `dynamic` with your real model type.
{{/has_model}}class {{module_class_prefix}}Service extends AgBaseService
    with
        AgRetrieveMixin<{{model_class}}, {{id_type}}>{{#generate_update}},
        AgUpdateMixin<{{model_class}}, {{id_type}}>{{/generate_update}}{{#generate_destroy}},
        AgDestroyMixin<{{id_type}}>{{/generate_destroy}} {
  {{module_class_prefix}}Service(super.apiProvider);

  // TODO: point this at a real endpoint declared in core/endpoints.dart.
  AgEndpoint get resourceEndpoint =>
      throw UnimplementedError('{{module_class_prefix}}Service.resourceEndpoint');

{{#has_model}}  {{model_class}} fromJson(Map<String, dynamic> json) =>
      {{model_class}}.fromJson(json);
{{#needs_to_json}}

  Map<String, dynamic> toJson({{model_class}} item) => item.toJson();
{{/needs_to_json}}{{/has_model}}{{^has_model}}  // TODO: replace `dynamic` with your model type, then decode/encode it.
  dynamic fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError('{{module_class_prefix}}Service.fromJson');
{{#needs_to_json}}

  Map<String, dynamic> toJson(dynamic item) =>
      throw UnimplementedError('{{module_class_prefix}}Service.toJson');
{{/needs_to_json}}{{/has_model}}

  @override
  Future<{{model_class}}> retrieve({{id_type}} id) => get(
    resourceEndpoint,
    pathParams: {'id': id},
    decode: (json) => fromJson(json! as Map<String, dynamic>),
  );
{{#generate_update}}

  @override
  Future<{{model_class}}> update({{id_type}} id, {{model_class}} item) => put(
    resourceEndpoint,
    pathParams: {'id': id},
    body: toJson(item),
    decode: (json) => fromJson(json! as Map<String, dynamic>),
  );
{{/generate_update}}{{#generate_destroy}}

  @override
  Future<void> destroy({{id_type}} id) =>
      delete(resourceEndpoint, pathParams: {'id': id});
{{/generate_destroy}}}