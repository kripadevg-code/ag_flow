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

  Future<dynamic> update(
    ProductDetailsPageArgument argument,
    dynamic item,
  ) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart and
    // encode/decode your detail type. Not mandatory — delete this method
    // (and its Repo/Controller counterparts) if this module never updates.
    throw UnimplementedError(
      'ProductDetailsService.update is not implemented yet.',
    );
  }

  Future<void> delete(ProductDetailsPageArgument argument) async {
    // TODO: replace with a real AgEndpoint from core/endpoints.dart. Not
    // mandatory — delete this method (and its Repo/Controller
    // counterparts) if this module never deletes.
    throw UnimplementedError(
      'ProductDetailsService.delete is not implemented yet.',
    );
  }
}
