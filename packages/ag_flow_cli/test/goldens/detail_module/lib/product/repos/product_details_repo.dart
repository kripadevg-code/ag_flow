import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/core/arguments/arguments.dart';
import 'package:sample_app/product/services/product_details_service.dart';

class ProductDetailsRepo extends AgBaseRepo {
  const ProductDetailsRepo(this._service);

  final ProductDetailsService _service;

  Future<dynamic> getByArgument(ProductDetailsPageArgument argument) =>
      _service.getByArgument(argument);
}
