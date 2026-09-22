import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/core/arguments/arguments.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/services/{{module_file_base}}_service.dart';

class {{module_class_prefix}}Repo extends AgBaseRepo {
  const {{module_class_prefix}}Repo(this._service);

  final {{module_class_prefix}}Service _service;

  Future<{{model_class}}> getByArgument({{module_class_prefix}}PageArgument argument) => _service.getByArgument(argument);
{{#generate_update}}

  Future<{{model_class}}> update({{module_class_prefix}}PageArgument argument, {{model_class}} item) =>
      _service.updateByArgument(argument, item);
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete({{module_class_prefix}}PageArgument argument) =>
      _service.deleteByArgument(argument);
{{/generate_delete}}
}
