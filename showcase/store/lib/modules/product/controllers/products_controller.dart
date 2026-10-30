import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:ag_showcase_store/modules/product/repos/products_repo.dart';

/// fakestoreapi doesn't paginate, so this controller has no `AgLoadMore`
/// — [fetch] returns the whole (optionally filtered) catalog.
///
/// The write actions don't refresh after writing: fakestoreapi never
/// persists a write, so a refresh would immediately undo what the user
/// just did. [create]/[destroy] reflect the mutation in the shown list
/// instead.
class ProductsController extends AgBaseController<List<Product>> {
  ProductsController(this._repo);

  final ProductsRepo _repo;

  String? _category;

  @override
  Future<List<Product>> fetch() {
    final category = _category;
    return category == null ? _repo.list() : _repo.listByCategory(category);
  }

  /// Kept as state, not applied once, so a pull-to-refresh keeps the filter.
  Future<void> filterByCategory(String? category) {
    _category = category;
    return refresh();
  }

  Future<void> create(Product item) async {
    final created = await _repo.create(item);
    emit(AgPageState.success([created, ...?state.dataOrNull]));
  }

  Future<void> destroy(int id) async {
    await _repo.destroy(id);
    final shown = state.dataOrNull ?? const <Product>[];
    emit(AgPageState.success(shown.where((p) => p.id != id).toList()));
  }
}
