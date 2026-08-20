import 'package:ag_flow/ag_flow.dart';

class {{module_class_prefix}}Service extends AgBaseService {
  {{module_class_prefix}}Service(super.apiProvider);

  Future<AgListPage<dynamic, int>> getPage(int pageKey) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // decode the response into your item type.
    throw UnimplementedError('{{module_class_prefix}}Service.getPage is not implemented yet.');
  }
{{#generate_add}}

  Future<dynamic> add(dynamic item) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // encode/decode your item type. Not mandatory — delete this method
    // (and its Repo/Controller counterparts) if this module never creates.
    throw UnimplementedError('{{module_class_prefix}}Service.add is not implemented yet.');
  }
{{/generate_add}}
{{#generate_update}}

  Future<dynamic> update(dynamic id, dynamic item) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // encode/decode your item type. Not mandatory — delete this method
    // (and its Repo/Controller counterparts) if this module never updates.
    throw UnimplementedError('{{module_class_prefix}}Service.update is not implemented yet.');
  }
{{/generate_update}}
{{#generate_delete}}

  Future<void> delete(dynamic id) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart. Not
    // mandatory — delete this method (and its Repo/Controller
    // counterparts) if this module never deletes.
    throw UnimplementedError('{{module_class_prefix}}Service.delete is not implemented yet.');
  }
{{/generate_delete}}
}
