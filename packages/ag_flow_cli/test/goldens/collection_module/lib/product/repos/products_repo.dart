import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/product/services/products_service.dart';

class ProductsRepo extends AgBaseRepo {
  const ProductsRepo(this._service);

  final ProductsService _service;

  Future<AgListPage<dynamic, int>> getPage(int pageKey) =>
      _service.getPage(pageKey);
}
