import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/modules/product/services/products_service.dart';

class ProductsRepo extends AgBaseRepo {
  const ProductsRepo(this._service);

  final ProductsService _service;

  Future<AgListPage<dynamic, int>> getPage(int pageKey) =>
      _service.getPage(pageKey);

  Future<dynamic> add(dynamic item) => _service.add(item);

  Future<dynamic> update(Object id, dynamic item) => _service.update(id, item);

  Future<void> delete(Object id) => _service.delete(id);
}
