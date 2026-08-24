import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:ag_showcase_store/modules/product/services/product_details_service.dart';

class ProductDetailsRepo extends AgBaseRepo {
  const ProductDetailsRepo(this._service);

  final ProductDetailsService _service;

  Future<Product> getById(int id) => _service.getById(id);

  Future<Product> update(int id, Product item) => _service.update(id, item);
}
