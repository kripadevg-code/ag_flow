import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/modules/product/services/product_details_service.dart';

/// The one Repo for this module: it decides where data comes from. Today
/// every method delegates to the Service; add caching or offline support
/// here without touching anything above it. [guard] turns Service errors
/// into an [AgRepoException], so controllers never see HTTP details.
class ProductDetailsRepo extends AgBaseRepo {
  ProductDetailsRepo(this._service);

  final ProductDetailsService _service;

  Future<dynamic> retrieve(Object id) => guard(() => _service.retrieve(id));

  Future<dynamic> update(Object id, dynamic item) =>
      guard(() => _service.update(id, item));

  Future<void> destroy(Object id) => guard(() => _service.destroy(id));
}
