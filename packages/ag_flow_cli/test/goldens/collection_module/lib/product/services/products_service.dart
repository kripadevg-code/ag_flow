import 'package:ag_flow/ag_flow.dart';

class ProductsService extends AgBaseService {
  ProductsService(super.apiProvider);

  Future<AgListPage<dynamic, int>> getPage(int pageKey) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // decode the response into your item type.
    throw UnimplementedError('ProductsService.getPage is not implemented yet.');
  }
}
