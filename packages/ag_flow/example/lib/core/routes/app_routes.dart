/// Route constants — the only source of route strings feature code may
/// use (see requirments/routes.md §4).
abstract class AppRoutes {
  static const String products = _Routes.products;
  static const String productDetails = _Routes.productDetails;
}

abstract class _Routes {
  static const products = '/products';
  static const productDetails = '/products/details';
}
