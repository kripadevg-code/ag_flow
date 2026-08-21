import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/core/arguments/arguments.dart';
import 'package:{{app_package_name}}/{{root_segment}}/repos/{{module_file_base}}_repo.dart';

class {{module_class_prefix}}Controller extends AgDetailController<dynamic, {{module_class_prefix}}PageArgument> {
  {{module_class_prefix}}Controller(this._repo);

  final {{module_class_prefix}}Repo _repo;

  @override
  Future<dynamic> fetch() => _repo.getByArgument(arguments);
{{#generate_update}}

  // Named updateItem — GetxController already declares update(), and a
  // same-named override with a different signature is a compile error.
  Future<void> updateItem(dynamic item) async {
    final updated = await _repo.update(arguments, item);
    emit(AgPageState.success(updated));
  }
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete() => _repo.delete(arguments);
{{/generate_delete}}
}
