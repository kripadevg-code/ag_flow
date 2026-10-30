import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:ag_showcase_store/modules/product/services/product_details_service.dart';

/// Plain delegation to the Service. To add caching or offline support,
/// change a method here.
class ProductDetailsRepo extends AgBaseRepo {
  const ProductDetailsRepo(this._service);

  final ProductDetailsService _service;

  Future<Product> retrieve(int id) => guard(() => _service.retrieve(id));

  Future<Product> update(int id, Product item) =>
      guard(() => _service.update(id, item));
}
