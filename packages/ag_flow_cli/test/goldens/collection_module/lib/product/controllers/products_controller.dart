import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/product/repos/products_repo.dart';

class ProductsController extends AgListController<dynamic, int> {
  ProductsController(this._repo) : super(initialPageKey: 1);

  final ProductsRepo _repo;

  @override
  Future<AgListPage<dynamic, int>> fetchPage(int pageKey) =>
      _repo.getPage(pageKey);
}
