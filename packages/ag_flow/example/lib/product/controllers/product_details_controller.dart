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

  /// Updates the product and reflects the result immediately — an
  /// optimistic-style update via [emit], the detail-page equivalent of
  /// [ProductsController.addProduct]'s [AgPaginationMixin.updateItems].
  Future<void> updateProduct(String name, String description) async {
    final updated = await _repo.update(
      arguments.productId,
      state.dataOrNull!.copyWith(name: name, description: description),
    );
    emit(AgPageState.success(updated));
  }
}
