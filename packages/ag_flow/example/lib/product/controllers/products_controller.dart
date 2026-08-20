import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/product/models/product.dart';
import 'package:ag_flow_example/product/repos/products_repo.dart';

class ProductsController extends AgListController<Product, int> {
  ProductsController(this._repo) : super(initialPageKey: 1);

  final ProductsRepo _repo;

  @override
  Future<AgListPage<Product, int>> fetchPage(int pageKey) =>
      _repo.getPage(pageKey);

  /// Creates a product and shows it immediately at the top of the list.
  /// A plain [refresh] wouldn't show it here — the demo backend
  /// (jsonplaceholder) doesn't actually persist writes, so re-fetching
  /// page 1 would never include what was just created.
  Future<void> addProduct(String name, String description) async {
    final created = await _repo.create(
      Product(id: '', name: name, description: description),
    );
    updateItems((items) => [created, ...items]);
  }

  Future<void> deleteProduct(String id) async {
    await _repo.delete(id);
    updateItems((items) => items.where((p) => p.id != id).toList());
  }
}
