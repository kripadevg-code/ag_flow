import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/services/{{module_file_base}}_service.dart';

/// The one Repo for this module: it decides where data comes from. Today
/// every method delegates to the Service; add caching or offline support
/// here without touching anything above it. [guard] turns Service errors
/// into an [AgRepoException], so controllers never see HTTP details.
class {{module_class_prefix}}Repo extends AgBaseRepo {
  {{module_class_prefix}}Repo(this._service);

  final {{module_class_prefix}}Service _service;

  Future<{{model_class}}> retrieve({{id_type}} id) =>
      guard(() => _service.retrieve(id));
{{#generate_update}}
  Future<{{model_class}}> update({{id_type}} id, {{model_class}} item) =>
      guard(() => _service.update(id, item));
{{/generate_update}}{{#generate_destroy}}
  Future<void> destroy({{id_type}} id) =>
      guard(() => _service.destroy(id));
{{/generate_destroy}}}
