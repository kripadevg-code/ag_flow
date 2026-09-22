import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/arguments/arguments.dart';

import 'app_routes.dart';

abstract class RouteManagement {
  // Auth
  static void goToLoginPage() => AgNavigator.toNamed<dynamic>(AppRoutes.login);

  static void goToHomePage() => AgNavigator.toNamed<dynamic>(AppRoutes.home);

  static void goToAdminPanelPage() =>
      AgNavigator.toNamed<dynamic>(AppRoutes.adminPanel);

  // Products
  static void goToProductsPage() =>
      AgNavigator.toNamed<dynamic>(AppRoutes.product);

  static void goToProductDetailsPage(ProductDetailsPageArgument argument) =>
      AgNavigator.toNamed<dynamic>(
        AppRoutes.productDetails,
        pathParameters: argument.toPathParameters(),
      );
}
