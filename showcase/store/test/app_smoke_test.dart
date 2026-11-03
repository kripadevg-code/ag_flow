import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/arguments/arguments.dart';
import 'package:ag_showcase_store/core/bindings/initial_binding.dart';
import 'package:ag_showcase_store/core/routes/route_management.dart';
import 'package:ag_showcase_store/main.dart';
import 'package:ag_showcase_store/modules/product/controllers/product_details_controller.dart';
import 'package:ag_showcase_store/modules/product/controllers/products_controller.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves every request from memory — no network — with objects carrying
/// every field this app's models read, and records `METHOD path`.
class FakeApi implements ApiProvider {
  final List<String> calls = [];

  static Map<String, dynamic> item(int id) => {
    'id': id,
    'userId': 1,
    'postId': 1,
    'title': 'Item $id',
    'body': 'body',
    'name': 'name',
    'email': 'a@b.c',
    'completed': false,
    'category': 'tools',
    'description': 'd',
    'image': '',
    'price': 10,
    'rating': {'rate': 4, 'count': 1},
  };

  @override
  Future<AgResponse<D>> send<D>(
    AgRequest request, {
    D Function(Object? json)? decode,
    AgCancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    final path = request.resolvePath();
    calls.add('${request.method.name} $path');
    final Object? json;
    if (request.method == AgHttpMethod.delete) {
      json = <String, dynamic>{};
    } else if (path.endsWith('/categories')) {
      json = ['tools', 'toys'];
    } else if (request.method == AgHttpMethod.post) {
      json = item(99); // a newly created resource gets a new id
    } else if (request.method != AgHttpMethod.get || RegExp(r'/\d+$').hasMatch(path)) {
      json = item(1);
    } else {
      json = [for (var i = 1; i <= 3; i++) item(i)];
    }
    return AgResponse<D>(
      statusCode: 200,
      data: decode != null ? decode(json) : json as D,
      headers: const {},
      duration: Duration.zero,
    );
  }
}

void main() {
  testWidgets('products: filter, add, delete, details update — offline', (
    tester,
  ) async {
    final api = FakeApi();
    InitialBinding().dependencies();
    AgLocator.put<ApiProvider>(api, permanent: true);

    await tester.pumpWidget(const StoreShowcaseApp());
    await tester.pumpAndSettle();
    final products = AgLocator.find<ProductsController>();
    expect(products.state.dataOrNull, hasLength(3));

    await products.filterByCategory('tools');
    await products.filterByCategory(null);
    await products.create(Product.fromJson(FakeApi.item(9)));
    expect(products.state.dataOrNull, hasLength(4), reason: 'optimistic add');
    await products.destroy(1);
    expect(products.state.dataOrNull, hasLength(3));

    RouteManagement.goToProductDetailsPage(
      const ProductDetailsPageArgument(productId: 2),
    );
    await tester.pumpAndSettle();
    final details = AgLocator.find<ProductDetailsController>();
    expect(details.lookupId, 2);
    await details.update(Product.fromJson(FakeApi.item(2)));
    expect(details.state, isA<AgPageSuccess<Product>>());

    expect(
      api.calls,
      containsAll(<String>[
        'GET /products/category/tools',
        'POST /products',
        'DELETE /products/1',
        'GET /products/2',
        'PUT /products/2',
      ]),
    );
  });
}
