import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/repos/{{module_file_base}}_repo.dart';

class {{module_class_prefix}}Controller extends AgListController<{{model_class}}, int> {
  {{module_class_prefix}}Controller(this._repo) : super(initialPageKey: 1);

  final {{module_class_prefix}}Repo _repo;

  @override
  Future<AgListPage<{{model_class}}, int>> fetchPage(int pageKey) => _repo.getPage(pageKey);
{{#generate_add}}

  Future<void> add({{model_class}} item) async {
    await _repo.add(item);
    await refresh();
  }
{{/generate_add}}
{{#generate_update}}

  Future<void> update({{id_type}} id, {{model_class}} item) async {
    await _repo.update(id, item);
    await refresh();
  }
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete({{id_type}} id) async {
    await _repo.delete(id);
    await refresh();
  }
{{/generate_delete}}
}
