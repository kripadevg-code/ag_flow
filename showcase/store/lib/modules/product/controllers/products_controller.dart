import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:ag_showcase_store/modules/product/repos/products_repo.dart';

class ProductsController extends AgListController<Product, int> {
  ProductsController(this._repo) : super(initialPageKey: 1);

  final ProductsRepo _repo;

  /// fakestoreapi.com has no real server-side pagination — the whole
  /// catalog comes back from one call. Page 1 fetches it; anything past
  /// that is simply exhausted.
  @override
  Future<AgListPage<Product, int>> fetchPage(int pageKey) async {
    if (pageKey > 1) return const AgListPage(items: [], hasMore: false);
    final items = await _repo.getAll();
    return AgListPage(items: items, hasMore: false);
  }

  /// Full-list replace via the pagination escape hatch — distinct from
  /// [add]/[delete] below, which mutate the existing list in place.
  Future<void> filterByCategory(String? category) async {
    final items = category == null
        ? await _repo.getAll()
        : await _repo.getByCategory(category);
    updateItems((_) => items);
  }

  Future<void> add(Product item) async {
    final created = await _repo.add(item);
    updateItems((items) => [created, ...items]);
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    updateItems((items) => items.where((p) => p.id != id).toList());
  }
}
