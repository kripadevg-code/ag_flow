import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/arguments/arguments.dart';
import 'package:ag_flow_example/product/models/product.dart';
import 'package:ag_flow_example/product/repos/product_details_repo.dart';

class ProductDetailsController
    extends AgDetailController<Product, ProductDetailsPageArgument> {
  ProductDetailsController(this._repo);

  final ProductDetailsRepo _repo;

  @override
  Future<Product> fetch() => _repo.getById(arguments.productId);
}
