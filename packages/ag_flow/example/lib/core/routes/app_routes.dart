/// Route constants — the only source of route strings feature code may
/// use (see requirments/routes.md §4).
///
/// The route constant/path is always the raw, never-pluralized segment
/// join, even for a root module — only the five architectural-layer
/// classes/files (`ProductsController`, `products_controller.dart`, ...)
/// get pluralized. See `ModuleSpec.routeConstant`/`routePath` in
/// ag_flow_cli, which this example's routing intentionally mirrors
/// byte-for-byte since it's the generator's own acceptance target.
abstract class AppRoutes {
  static const String product = _Routes.product;
  static const String productDetails = _Routes.productDetails;
}

abstract class _Routes {
  static const product = '/product';
  static const productDetails = '/product/details';
}
