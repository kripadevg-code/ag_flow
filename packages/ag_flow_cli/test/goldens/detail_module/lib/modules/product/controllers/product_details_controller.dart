import 'package:ag_flow/ag_flow.dart';
import 'package:sample_app/core/arguments/arguments.dart';
import 'package:sample_app/modules/product/repos/product_details_repo.dart';

/// Loads one resource through the Repo; each write goes to the same
/// resource and shows the result.
class ProductDetailsController extends AgBaseController<dynamic> {
  ProductDetailsController(this._repo)
    : argument = ProductDetailsPageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final ProductDetailsRepo _repo;

  /// This page's argument, read from the route's path parameters — so it
  /// opens correctly from a deep link, a notification, or a reloaded web
  /// URL, not only from an in-app push.
  final ProductDetailsPageArgument argument;

  /// Which resource this page shows: an id, a slug, or a record for a
  /// composite key — whatever the Service's lookup type is.
  Object get lookupId => argument.id;

  @override
  Future<dynamic> fetch() => _repo.retrieve(lookupId);

  Future<void> update(dynamic item) async {
    emit(AgPageState.success(await _repo.update(lookupId, item)));
  }

  Future<void> destroy() => _repo.destroy(lookupId);
}
