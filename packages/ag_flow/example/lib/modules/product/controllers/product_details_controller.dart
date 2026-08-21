import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/arguments/arguments.dart';
import 'package:ag_flow_example/modules/product/repos/product_details_repo.dart';

class ProductDetailsController
    extends AgDetailController<dynamic, ProductDetailsPageArgument> {
  ProductDetailsController(this._repo);

  final ProductDetailsRepo _repo;

  @override
  Future<dynamic> fetch() => _repo.getByArgument(arguments);

  // Named updateItem — GetxController already declares update(), and a
  // same-named override with a different signature is a compile error.
  Future<void> updateItem(dynamic item) async {
    final updated = await _repo.update(arguments, item);
    emit(AgPageState.success(updated));
  }

  Future<void> delete() => _repo.delete(arguments);
}
