import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/modules/product/repos/products_repo.dart';

class ProductsController extends AgListController<dynamic, int> {
  ProductsController(this._repo) : super(initialPageKey: 1);

  final ProductsRepo _repo;

  @override
  Future<AgListPage<dynamic, int>> fetchPage(int pageKey) =>
      _repo.getPage(pageKey);

  Future<void> add(dynamic item) async {
    await _repo.add(item);
    await refresh();
  }

  // Named updateItem — GetxController already declares update(), and a
  // same-named override with a different signature is a compile error.
  Future<void> updateItem(dynamic id, dynamic item) async {
    await _repo.update(id, item);
    await refresh();
  }

  Future<void> delete(dynamic id) async {
    await _repo.delete(id);
    await refresh();
  }
}
