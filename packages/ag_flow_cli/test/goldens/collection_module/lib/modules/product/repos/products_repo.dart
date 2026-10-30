import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/modules/product/services/products_service.dart';

/// The one Repo for this module: it decides where data comes from. Today
/// every method delegates to the Service; add caching or offline support
/// here without touching anything above it.
class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service);

  final ProductsService _service;

  Future<List<dynamic>> list() => _service.list();

  Future<dynamic> create(dynamic item) => _service.create(item);

  Future<dynamic> update(Object id, dynamic item) => _service.update(id, item);

  Future<void> destroy(Object id) => _service.destroy(id);
}
