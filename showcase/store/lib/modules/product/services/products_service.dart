import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/endpoints.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';

/// fakestoreapi returns the entire catalog in one response and never
/// paginates — a completely different backend contract from the blog
/// app's, yet this file has the identical shape. The whole difference is
/// that this Service declares no `pagination`, so `list` takes no page.
///
/// That is the point: a developer reading any AG Service in any app knows
/// where to look, and a backend's quirks stay in one place rather than
/// leaking into the layers above.
///
/// Each mixin is one action this module actually performs: list, create
/// and destroy. The action mixins only fix each method's name and types;
/// the bodies are this Service's own.
class ProductsService extends AgBaseService
    with AgListMixin<Product>, AgCreateMixin<Product>, AgDestroyMixin<int> {
  ProductsService(super.apiProvider);

  @override
  Future<List<Product>> list() => get(ProductEndpoints.products, decode: _products);

  @override
  Future<Product> create(Product item) => post(
    ProductEndpoints.products,
    body: item.toJson(),
    decode: (json) => Product.fromJson(json! as Map<String, dynamic>),
  );

  @override
  Future<void> destroy(int id) => delete(ProductEndpoints.productById, pathParams: {'id': id});

  // Feature-specific reads sit alongside the mixed-in actions, written
  // with the same verb methods as every action body.
  Future<List<Product>> listByCategory(String category) => get(
    ProductEndpoints.productsByCategory,
    pathParams: {'category': category},
    decode: _products,
  );

  /// An array of bare strings rather than objects.
  Future<List<String>> categories() => get(
    ProductEndpoints.categories,
    decode: (json) => (json! as List<Object?>).cast<String>(),
  );

  static List<Product> _products(Object? json) => [
    for (final item in json! as List<Object?>) Product.fromJson(item! as Map<String, dynamic>),
  ];
}
