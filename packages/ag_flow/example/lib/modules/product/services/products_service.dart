import 'package:ag_flow/ag_flow.dart';

class ProductsService extends AgBaseService {
  ProductsService(super.apiProvider);

  Future<AgListPage<dynamic, int>> getPage(int pageKey) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // decode the response into your item type.
    throw UnimplementedError('ProductsService.getPage is not implemented yet.');
  }

  Future<dynamic> add(dynamic item) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // encode/decode your item type. Not mandatory — delete this method
    // (and its Repo/Controller counterparts) if this module never creates.
    throw UnimplementedError('ProductsService.add is not implemented yet.');
  }

  Future<dynamic> update(dynamic id, dynamic item) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // encode/decode your item type. Not mandatory — delete this method
    // (and its Repo/Controller counterparts) if this module never updates.
    throw UnimplementedError('ProductsService.update is not implemented yet.');
  }

  Future<void> delete(dynamic id) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart. Not
    // mandatory — delete this method (and its Repo/Controller
    // counterparts) if this module never deletes.
    throw UnimplementedError('ProductsService.delete is not implemented yet.');
  }
}
