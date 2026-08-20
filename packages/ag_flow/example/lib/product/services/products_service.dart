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

  /// `AgCrudService`'s `add`/`getAll`/`getById`/`update`/`delete` shape
  /// doesn't fit every module — this one needs a *paginated* getPage, so
  /// it's entirely hand-written instead of mixing in `AgCrudService`. AG
  /// never requires a fixed CRUD method set; define exactly what a
  /// feature needs, named however reads best for it.
  Future<Product> create(Product product) async {
    final response = await send<Map<String, dynamic>>(
      AgRequest(
        endpoint: ProductEndpoints.products,
        method: AgHttpMethod.post,
        body: product.toJson(),
      ),
      decode: (json) => json! as Map<String, dynamic>,
    );
    return Product.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await send<dynamic>(
      AgRequest(
        endpoint: ProductEndpoints.productById,
        method: AgHttpMethod.delete,
        pathParams: {'id': id},
      ),
    );
  }
}
