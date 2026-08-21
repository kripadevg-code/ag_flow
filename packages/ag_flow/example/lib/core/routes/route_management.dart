import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/arguments/arguments.dart';

import 'app_routes.dart';

abstract class RouteManagement {
  static void goToProductsPage() {
    Get.toNamed<dynamic>(AppRoutes.product);
  }

  static void goToProductDetailsPage(ProductDetailsPageArgument argument) {
    Get.toNamed<dynamic>(AppRoutes.productDetails, arguments: argument);
  }
}
