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

  Future<List<{{model_class}}>> list({{#paginate}}{int page = 1}{{/paginate}}) =>
      guard(() => _service.list({{#paginate}}page: page{{/paginate}}));
{{#paginate}}
  /// Whether [items] was the backend's last page.
  bool isLastPage(List<{{model_class}}> items) =>
      _service.pagination.isLastPage(items);
{{/paginate}}{{#generate_create}}
  Future<{{model_class}}> create({{model_class}} item) =>
      guard(() => _service.create(item));
{{/generate_create}}{{#generate_update}}
  Future<{{model_class}}> update({{id_type}} id, {{model_class}} item) =>
      guard(() => _service.update(id, item));
{{/generate_update}}{{#generate_destroy}}
  Future<void> destroy({{id_type}} id) =>
      guard(() => _service.destroy(id));
{{/generate_destroy}}}
