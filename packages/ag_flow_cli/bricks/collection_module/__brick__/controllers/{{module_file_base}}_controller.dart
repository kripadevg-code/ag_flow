import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{root_segment}}/repos/{{module_file_base}}_repo.dart';

class {{module_class_prefix}}Controller extends AgListController<dynamic, int> {
  {{module_class_prefix}}Controller(this._repo) : super(initialPageKey: 1);

  final {{module_class_prefix}}Repo _repo;

  @override
  Future<AgListPage<dynamic, int>> fetchPage(int pageKey) => _repo.getPage(pageKey);
}
