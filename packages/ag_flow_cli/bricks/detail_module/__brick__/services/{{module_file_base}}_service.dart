import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/core/arguments/arguments.dart';

class {{module_class_prefix}}Service extends AgBaseService {
  {{module_class_prefix}}Service(super.apiProvider);

  Future<dynamic> getByArgument({{module_class_prefix}}PageArgument argument) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // decode the response into your detail type.
    throw UnimplementedError('{{module_class_prefix}}Service.getByArgument is not implemented yet.');
  }
{{#generate_update}}

  Future<dynamic> update({{module_class_prefix}}PageArgument argument, dynamic item) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // encode/decode your detail type. Not mandatory — delete this method
    // (and its Repo/Controller counterparts) if this module never updates.
    throw UnimplementedError('{{module_class_prefix}}Service.update is not implemented yet.');
  }
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete({{module_class_prefix}}PageArgument argument) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart. Not
    // mandatory — delete this method (and its Repo/Controller
    // counterparts) if this module never deletes.
    throw UnimplementedError('{{module_class_prefix}}Service.delete is not implemented yet.');
  }
{{/generate_delete}}
}
