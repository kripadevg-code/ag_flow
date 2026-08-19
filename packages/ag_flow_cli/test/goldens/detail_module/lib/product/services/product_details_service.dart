import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/core/arguments/arguments.dart';

class ProductDetailsService extends AgBaseService {
  ProductDetailsService(super.apiProvider);

  Future<dynamic> getByArgument(ProductDetailsPageArgument argument) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // decode the response into your detail type.
    throw UnimplementedError(
      'ProductDetailsService.getByArgument is not implemented yet.',
    );
  }
}
