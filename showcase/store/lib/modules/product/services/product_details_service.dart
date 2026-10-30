import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/endpoints.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';

/// Mixes in exactly the actions the detail page uses — [retrieve] and
/// [update] against [ProductEndpoints.productById] — and exposes no action
/// the page never performs.
class ProductDetailsService extends AgBaseService
    with AgRetrieveMixin<Product, int>, AgUpdateMixin<Product, int> {
  ProductDetailsService(super.apiProvider);

  @override
  Future<Product> retrieve(int id) => get(
    ProductEndpoints.productById,
    pathParams: {'id': id},
    decode: (json) => Product.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<Product> update(int id, Product item) => put(
    ProductEndpoints.productById,
    pathParams: {'id': id},
    body: item.toJson(),
    decode: (json) => Product.fromJson(json! as Map<String, dynamic>),
  );
}
