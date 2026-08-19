import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/endpoints.dart';
import 'package:ag_flow_example/product/models/product.dart';

/// Owns API communication for the product collection. Every child module
/// (e.g. [ProductDetailsService]) gets its own Service by default — see
/// requirments/ag_framework.md §40.
class ProductsService extends AgBaseService {
  ProductsService(super.apiProvider);

  Future<List<Product>> getPage(int page, {int limit = 10}) async {
    final response = await send<List<dynamic>>(
      AgRequest(
        endpoint: ProductEndpoints.products,
        queryParams: {'_page': page, '_limit': limit},
      ),
      decode: (json) => json! as List<dynamic>,
    );
    return response.data
        .cast<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }
}
