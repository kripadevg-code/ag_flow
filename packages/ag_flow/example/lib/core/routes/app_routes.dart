abstract class AppRoutes {
  static const String initial = _Routes.initial;
  static const String login = _Routes.login;
  static const String home = _Routes.home;
  static const String adminPanel = _Routes.adminPanel;
  static const String product = _Routes.product;
  static const String productDetails = _Routes.productDetails;
}

abstract class _Routes {
  static const String initial = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String adminPanel = '/admin';
  static const String product = '/product';
  static const String productDetails = '/product/details/:id';
}
