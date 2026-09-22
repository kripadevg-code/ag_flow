import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/services/{{module_file_base}}_service.dart';

class {{module_class_prefix}}Repo extends AgBaseRepo {
  const {{module_class_prefix}}Repo(this._service);

  final {{module_class_prefix}}Service _service;

  Future<AgListPage<{{model_class}}, int>> getPage(int pageKey) => _service.getPage(pageKey);
{{#generate_add}}

  Future<{{model_class}}> add({{model_class}} item) => _service.add(item);
{{/generate_add}}
{{#generate_update}}

  Future<{{model_class}}> update({{id_type}} id, {{model_class}} item) => _service.update(id, item);
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete({{id_type}} id) => _service.delete(id);
{{/generate_delete}}
}
