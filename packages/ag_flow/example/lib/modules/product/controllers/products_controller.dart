import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/modules/product/repos/products_repo.dart';

/// Loads the list through the Repo, one page at a time.
/// Each write goes through the Repo and then refreshes the list. Add
/// feature-specific methods (search, filter) alongside them freely.
class ProductsController extends AgBaseController<List<dynamic>> with AgLoadMore<dynamic> {
  ProductsController(this._repo);

  final ProductsRepo _repo;

  @override
  Future<List<dynamic>> list({int page = 1}) => _repo.list(page: page);

  @override
  bool isLastPage(List<dynamic> items) => _repo.isLastPage(items);

  Future<void> create(dynamic item) async {
    await _repo.create(item);
    await refresh();
  }

  Future<void> update(Object id, dynamic item) async {
    await _repo.update(id, item);
    await refresh();
  }

  Future<void> destroy(Object id) async {
    await _repo.destroy(id);
    await refresh();
  }
}
