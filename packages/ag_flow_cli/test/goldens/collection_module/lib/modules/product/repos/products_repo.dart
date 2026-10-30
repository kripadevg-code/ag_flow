import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/modules/product/services/products_service.dart';

/// The one Repo for this module: it decides where data comes from. Today
/// every method delegates to the Service; add caching or offline support
/// here without touching anything above it. [guard] turns Service errors
/// into an [AgRepoException], so controllers never see HTTP details.
class ProductsRepo extends AgBaseRepo {
  ProductsRepo(this._service);

  final ProductsService _service;

  Future<List<dynamic>> list() => guard(() => _service.list());

  Future<dynamic> create(dynamic item) => guard(() => _service.create(item));

  Future<dynamic> update(Object id, dynamic item) =>
      guard(() => _service.update(id, item));

  Future<void> destroy(Object id) => guard(() => _service.destroy(id));
}
