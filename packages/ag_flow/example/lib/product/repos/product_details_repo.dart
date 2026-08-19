import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/product/models/product.dart';
import 'package:ag_flow_example/product/services/product_details_service.dart';

class ProductDetailsRepo extends AgBaseRepo {
  const ProductDetailsRepo(this._service);

  final ProductDetailsService _service;

  Future<Product> getById(String id) => _service.getById(id);
}
