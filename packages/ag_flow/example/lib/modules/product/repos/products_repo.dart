import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/modules/product/services/products_service.dart';

/// The one Repo for this module: it decides where data comes from. Today
/// every method delegates to the Service; add caching or offline support
/// here without touching anything above it.
class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service);

  final ProductsService _service;

  Future<List<dynamic>> list({int page = 1}) =>
      guard(() => _service.list(page: page));

  /// Whether [items] was the backend's last page.
  bool isLastPage(List<dynamic> items) => _service.pagination.isLastPage(items);

  Future<dynamic> create(dynamic item) => guard(() => _service.create(item));

  Future<dynamic> update(Object id, dynamic item) =>
      guard(() => _service.update(id, item));

  Future<void> destroy(Object id) => guard(() => _service.destroy(id));
}
