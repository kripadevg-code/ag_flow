import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/core/arguments/arguments.dart';
import 'package:{{app_package_name}}/{{root_segment}}/services/{{module_file_base}}_service.dart';

class {{module_class_prefix}}Repo extends AgBaseRepo {
  const {{module_class_prefix}}Repo(this._service);

  final {{module_class_prefix}}Service _service;

  Future<dynamic> getByArgument({{module_class_prefix}}PageArgument argument) => _service.getByArgument(argument);
{{#generate_update}}

  Future<dynamic> update({{module_class_prefix}}PageArgument argument, dynamic item) =>
      _service.update(argument, item);
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete({{module_class_prefix}}PageArgument argument) => _service.delete(argument);
{{/generate_delete}}
}
