import 'package:ag_flow/ag_flow.dart';
{{#has_model}}import 'package:{{app_package_name}}/{{{module_import_path}}}/models/{{model_file_base}}.dart';
{{/has_model}}import 'package:{{app_package_name}}/core/arguments/arguments.dart';
import 'package:{{app_package_name}}/{{{module_import_path}}}/repos/{{module_file_base}}_repo.dart';

/// Loads one resource through the Repo; each write goes to the same
/// resource and shows the result.
class {{module_class_prefix}}Controller extends AgBaseController<{{model_class}}>
    with AgRetrieve<{{model_class}}> {
  {{module_class_prefix}}Controller(this._repo)
    : argument = {{module_class_prefix}}PageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final {{module_class_prefix}}Repo _repo;

  /// This page's argument, read from the route's path parameters — so it
  /// opens correctly from a deep link, a notification, or a reloaded web
  /// URL, not only from an in-app push.
  final {{module_class_prefix}}PageArgument argument;

  /// Which resource this page shows: an id, a slug, or a record for a
  /// composite key — whatever the Service's lookup type is.
  {{id_type}} get lookupId => {{{lookup_id_expression}}};

  @override
  Future<{{model_class}}> retrieve() => _repo.retrieve(lookupId);
{{#generate_update}}
  Future<void> update({{model_class}} item) async {
    emit(AgPageState.success(await _repo.update(lookupId, item)));
  }
{{/generate_update}}{{#generate_destroy}}
  Future<void> destroy() => _repo.destroy(lookupId);
{{/generate_destroy}}}
