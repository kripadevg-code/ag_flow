import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/modules/product/models/product.dart';
import 'package:ag_flow_example/modules/product/services/products_service.dart';

class ProductsRepo extends AgBaseRepo {
  const ProductsRepo(this._service);

  final ProductsService _service;

  Future<AgListPage<Product, int>> getPage(int page) async {
    final items = await _service.getPage(page);
    return AgListPage(
      items: items,
      hasMore: items.isNotEmpty,
      nextPageKey: items.isEmpty ? null : page + 1,
    );
  }
}
