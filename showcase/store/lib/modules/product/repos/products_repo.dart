import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:ag_showcase_store/modules/product/services/products_service.dart';

class ProductsRepo extends AgBaseRepo {
  const ProductsRepo(this._service);

  final ProductsService _service;

  Future<List<Product>> getAll() => _service.getAll();

  Future<List<Product>> getByCategory(String category) =>
      _service.getByCategory(category);

  Future<List<String>> getCategories() => _service.getCategories();

  Future<Product> add(Product item) => _service.add(item);

  Future<void> delete(int id) => _service.delete(id);
}
