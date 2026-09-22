import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/core/arguments/arguments.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/repos/{{module_file_base}}_repo.dart';

class {{module_class_prefix}}Controller extends AgDetailController<{{model_class}}, {{module_class_prefix}}PageArgument> {
  {{module_class_prefix}}Controller(this._repo);

  final {{module_class_prefix}}Repo _repo;

  /// Rebuilds this page's argument from the route's path parameters, so
  /// it opens correctly from a deep link, a notification, or a reloaded
  /// web URL — not only from an in-app push.
  @override
  {{module_class_prefix}}PageArgument? argumentsFromPath(
    Map<String, String> pathParameters,
  ) => {{module_class_prefix}}PageArgument.fromPathParameters(pathParameters);

  @override
  Future<{{model_class}}> fetch() => _repo.getByArgument(arguments);
{{#generate_update}}

  Future<void> update({{model_class}} item) async {
    final updated = await _repo.update(arguments, item);
    emit(AgPageState.success(updated));
  }
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete() => _repo.delete(arguments);
{{/generate_delete}}
}
