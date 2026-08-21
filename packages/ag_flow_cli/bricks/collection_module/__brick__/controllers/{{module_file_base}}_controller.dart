import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/{{root_segment}}/repos/{{module_file_base}}_repo.dart';

class {{module_class_prefix}}Controller extends AgListController<dynamic, int> {
  {{module_class_prefix}}Controller(this._repo) : super(initialPageKey: 1);

  final {{module_class_prefix}}Repo _repo;

  @override
  Future<AgListPage<dynamic, int>> fetchPage(int pageKey) => _repo.getPage(pageKey);
{{#generate_add}}

  Future<void> add(dynamic item) async {
    await _repo.add(item);
    await refresh();
  }
{{/generate_add}}
{{#generate_update}}

  // Named updateItem — GetxController already declares update(), and a
  // same-named override with a different signature is a compile error.
  Future<void> updateItem(dynamic id, dynamic item) async {
    await _repo.update(id, item);
    await refresh();
  }
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete(dynamic id) async {
    await _repo.delete(id);
    await refresh();
  }
{{/generate_delete}}
}
