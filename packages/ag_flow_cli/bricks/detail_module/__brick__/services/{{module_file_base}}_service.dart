import 'package:ag_flow/ag_flow.dart';
import 'package:{{app_package_name}}/core/arguments/arguments.dart';

class {{module_class_prefix}}Service extends AgBaseService {
  {{module_class_prefix}}Service(super.apiProvider);

  Future<dynamic> getByArgument({{module_class_prefix}}PageArgument argument) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // decode the response into your detail type.
    throw UnimplementedError('{{module_class_prefix}}Service.getByArgument is not implemented yet.');
  }
}
