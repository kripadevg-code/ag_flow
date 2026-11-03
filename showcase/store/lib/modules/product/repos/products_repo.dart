import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:ag_showcase_store/modules/product/services/products_service.dart';

/// The module's one Repo: plain delegation to the Service today, and the
/// place caching or offline support would go.
class ProductsRepo extends AgBaseRepo {
  const ProductsRepo(this._service);

  final ProductsService _service;

  Future<List<Product>> list() => guard(() => _service.list());

  Future<Product> create(Product item) => guard(() => _service.create(item));

  Future<void> destroy(int id) => guard(() => _service.destroy(id));

  Future<List<Product>> listByCategory(String category) =>
      guard(() => _service.listByCategory(category));

  Future<List<String>> categories() => guard(() => _service.categories());
}
