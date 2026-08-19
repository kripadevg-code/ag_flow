import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/product/models/product.dart';
import 'package:ag_flow_example/product/repos/products_repo.dart';

class ProductsController extends AgListController<Product, int> {
  ProductsController(this._repo) : super(initialPageKey: 1);

  final ProductsRepo _repo;

  @override
  Future<AgListPage<Product, int>> fetchPage(int pageKey) =>
      _repo.getPage(pageKey);
}
