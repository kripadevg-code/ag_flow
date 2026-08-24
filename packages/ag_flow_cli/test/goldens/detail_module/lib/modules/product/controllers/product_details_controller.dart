import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/core/arguments/arguments.dart';
import 'package:sample_app/modules/product/repos/product_details_repo.dart';

class ProductDetailsController
    extends AgDetailController<dynamic, ProductDetailsPageArgument> {
  ProductDetailsController(this._repo);

  final ProductDetailsRepo _repo;

  @override
  Future<dynamic> fetch() => _repo.getByArgument(arguments);

  Future<void> update(dynamic item) async {
    final updated = await _repo.update(arguments, item);
    emit(AgPageState.success(updated));
  }

  Future<void> delete() => _repo.delete(arguments);
}
