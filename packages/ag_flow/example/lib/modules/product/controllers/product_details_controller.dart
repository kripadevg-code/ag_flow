import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/arguments/arguments.dart';
import 'package:ag_flow_example/modules/product/repos/product_details_repo.dart';

class ProductDetailsController
    extends AgDetailController<dynamic, ProductDetailsPageArgument> {
  ProductDetailsController(this._repo);

  final ProductDetailsRepo _repo;

  /// Rebuilds this page's argument from the route's path parameters,
  /// so it opens correctly from a deep link as well as an in-app push.
  @override
  ProductDetailsPageArgument? argumentsFromPath(
    Map<String, String> pathParameters,
  ) => ProductDetailsPageArgument.fromPathParameters(pathParameters);

  @override
  Future<dynamic> fetch() => _repo.getByArgument(arguments);

  Future<void> update(dynamic item) async {
    final updated = await _repo.update(arguments, item);
    emit(AgPageState.success(updated));
  }

  Future<void> delete() => _repo.delete(arguments);
}
