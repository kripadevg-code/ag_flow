import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/arguments/arguments.dart';

import 'app_routes.dart';

abstract class RouteManagement {
  static void goToProductsPage() {
    AgNavigator.toNamed<dynamic>(AppRoutes.product);
  }

  static void goToProductDetailsPage(ProductDetailsPageArgument argument) {
    AgNavigator.toNamed<dynamic>(AppRoutes.productDetails, arguments: argument);
  }
}
