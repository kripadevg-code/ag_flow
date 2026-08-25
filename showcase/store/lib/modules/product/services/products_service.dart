import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/endpoints.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';

/// fakestoreapi returns the entire catalog in one response and never
/// paginates — a completely different backend contract from the blog
/// app's, yet this file has the identical shape. The whole difference is
/// [pageStrategy] naming [AgSinglePageStrategy] instead of a paging one.
///
/// That is the point: a developer reading any AG Service in any app knows
/// where to look, and a backend's quirks stay declarations rather than
/// leaking into imperative code.
class ProductsService extends AgBaseService
    with AgCrudService<Product, int>, AgPagedService<Product, int> {
  ProductsService(super.apiProvider);

  @override
  AgEndpoint get collectionEndpoint => ProductEndpoints.products;

  @override
  AgEndpoint get resourceEndpoint => ProductEndpoints.productById;

  @override
  AgPageStrategy<int> get pageStrategy => const AgSinglePageStrategy();

  @override
  Product fromJson(Map<String, dynamic> json) => Product.fromJson(json);

  @override
  Map<String, dynamic> toJson(Product item) => item.toJson();

  // Feature-specific reads sit alongside the inherited CRUD — one
  // declarative line each, via the same decoding path.
  Future<List<Product>> getByCategory(String category) => fetchList(
    AgRequest(
      endpoint: ProductEndpoints.productsByCategory,
      pathParams: {'category': category},
    ),
    Product.fromJson,
  );

  /// An array of bare strings rather than objects, so this one reads the
  /// payload directly instead of going through [fromJson].
  Future<List<String>> getCategories() async {
    final response = await send<Object?>(
      AgRequest(endpoint: ProductEndpoints.categories),
      decode: (json) => json,
    );
    return (envelope.payloadOf(response.data)! as List<dynamic>).cast<String>();
  }
}
