import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{root_segment}}/services/{{module_file_base}}_service.dart';

class {{module_class_prefix}}Repo extends AgBaseRepo {
  const {{module_class_prefix}}Repo(this._service);

  final {{module_class_prefix}}Service _service;

  Future<AgListPage<dynamic, int>> getPage(int pageKey) => _service.getPage(pageKey);
}
