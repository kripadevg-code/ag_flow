import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/arguments/arguments.dart';
import 'package:ag_showcase_store/modules/product/models/product.dart';
import 'package:ag_showcase_store/modules/product/repos/product_details_repo.dart';

/// Loads the product named by the route; [update] shows what the backend
/// returned.
class ProductDetailsController extends AgBaseController<Product> {
  ProductDetailsController(this._repo)
    : argument = ProductDetailsPageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final ProductDetailsRepo _repo;

  final ProductDetailsPageArgument argument;

  int get lookupId => argument.productId;

  @override
  Future<Product> fetch() => _repo.retrieve(lookupId);

  Future<void> update(Product item) async {
    emit(AgPageState.success(await _repo.update(lookupId, item)));
  }
}
