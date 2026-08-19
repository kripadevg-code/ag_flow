import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/endpoints.dart';
import 'package:ag_flow_example/modules/product/models/product.dart';

/// The `details` child module's own Service (see
/// requirments/ag_framework.md §40) — it does not route through
/// [ProductsService].
class ProductDetailsService extends AgBaseService {
  ProductDetailsService(super.apiProvider);

  Future<Product> getById(String id) async {
    final response = await send<Map<String, dynamic>>(
      AgRequest(endpoint: ProductEndpoints.productById, pathParams: {'id': id}),
      decode: (json) => json! as Map<String, dynamic>,
    );
    return Product.fromJson(response.data);
  }
}
