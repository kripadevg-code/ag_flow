import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/endpoints.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';

class ProductsService extends AgBaseService with AgCrudService<Product, int> {
  ProductsService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => ProductEndpoints.products;
  @override
  AgEndpoint get resourceEndpoint => ProductEndpoints.productById;
  @override
  Product fromJson(Map<String, dynamic> json) => Product.fromJson(json);
  @override
  Map<String, dynamic> toJson(Product item) => item.toJson();

  // Feature-specific methods alongside the mixin's add/getAll/getById/
  // update/delete — AgCrudService never prevents this.
  Future<List<Product>> getByCategory(String category) async {
    final response = await send<List<dynamic>>(
      AgRequest(
        endpoint: ProductEndpoints.productsByCategory,
        pathParams: {'category': category},
      ),
      decode: (json) => json! as List<dynamic>,
    );
    return response.data
        .cast<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<List<String>> getCategories() async {
    final response = await send<List<dynamic>>(
      AgRequest(endpoint: ProductEndpoints.categories),
      decode: (json) => json! as List<dynamic>,
    );
    return response.data.cast<String>();
  }
}
