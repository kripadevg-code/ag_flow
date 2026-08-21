import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/services/{{module_file_base}}_service.dart';

class {{module_class_prefix}}Repo extends AgBaseRepo {
  const {{module_class_prefix}}Repo(this._service);

  final {{module_class_prefix}}Service _service;

  Future<AgListPage<dynamic, int>> getPage(int pageKey) => _service.getPage(pageKey);
{{#generate_add}}

  Future<dynamic> add(dynamic item) => _service.add(item);
{{/generate_add}}
{{#generate_update}}

  Future<dynamic> update(dynamic id, dynamic item) => _service.update(id, item);
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete(dynamic id) => _service.delete(id);
{{/generate_delete}}
}
