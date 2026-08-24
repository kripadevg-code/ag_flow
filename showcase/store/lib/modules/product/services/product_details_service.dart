import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/endpoints.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';

/// Backs the detail page with the same `AgCrudService` shape as
/// [ProductEndpoints.products]/[ProductEndpoints.productById] — the
/// mixin provides [getById]/[update] directly, so this Service needs no
/// hand-written network code of its own.
class ProductDetailsService extends AgBaseService
    with AgCrudService<Product, int> {
  ProductDetailsService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => ProductEndpoints.products;
  @override
  AgEndpoint get resourceEndpoint => ProductEndpoints.productById;
  @override
  Product fromJson(Map<String, dynamic> json) => Product.fromJson(json);
  @override
  Map<String, dynamic> toJson(Product item) => item.toJson();
}
