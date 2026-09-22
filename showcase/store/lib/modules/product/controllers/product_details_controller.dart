import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/arguments/arguments.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:ag_showcase_store/modules/product/repos/product_details_repo.dart';

class ProductDetailsController
    extends AgDetailController<Product, ProductDetailsPageArgument> {
  ProductDetailsController(this._repo);

  final ProductDetailsRepo _repo;

  /// Rebuilds this page's argument from the route's path parameters,
  /// so it opens correctly from a deep link as well as an in-app push.
  @override
  ProductDetailsPageArgument? argumentsFromPath(
    Map<String, String> pathParameters,
  ) => ProductDetailsPageArgument.fromPathParameters(pathParameters);

  @override
  Future<Product> fetch() => _repo.getById(arguments.productId);

  Future<void> update(Product item) async {
    final updated = await _repo.update(arguments.productId, item);
    emit(AgPageState.success(updated));
  }
}
