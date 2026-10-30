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
  Future<List<Product>> list() =>
      _products(AgRequest(endpoint: ProductEndpoints.products));

  @override
  Future<Product> create(Product item) async {
    final response = await send<Product>(
      AgRequest(
        endpoint: ProductEndpoints.products,
        method: AgHttpMethod.post,
        body: item.toJson(),
      ),
      decode: (json) => Product.fromJson(json! as Map<String, dynamic>),
    );
    return response.data;
  }

  @override
  Future<void> destroy(int id) async {
    await send<void>(
      AgRequest(
        endpoint: ProductEndpoints.productById,
        method: AgHttpMethod.delete,
        pathParams: {'id': id},
      ),
    );
  }

  // Feature-specific reads sit alongside the mixed-in actions, written
  // with the same `send` as every action body.
  Future<List<Product>> listByCategory(String category) => _products(
    AgRequest(
      endpoint: ProductEndpoints.productsByCategory,
      pathParams: {'category': category},
    ),
  );

  /// An array of bare strings rather than objects.
  Future<List<String>> categories() async {
    final response = await send<List<String>>(
      AgRequest(endpoint: ProductEndpoints.categories),
      decode: (json) => (json! as List<Object?>).cast<String>(),
    );
    return response.data;
  }

  Future<List<Product>> _products(AgRequest request) async {
    final response = await send<List<Product>>(
      request,
      decode: (json) => [
        for (final item in json! as List<Object?>)
          Product.fromJson(item! as Map<String, dynamic>),
      ],
    );
    return response.data;
  }
}
