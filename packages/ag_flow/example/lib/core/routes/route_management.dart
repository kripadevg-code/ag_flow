import 'dart:async';

import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/arguments/arguments.dart';
import 'package:ag_flow_example/core/routes/app_routes.dart';

/// The only recommended application-level navigation API (see
/// requirments/routes.md §10) — feature code calls
/// `RouteManagement.goToXPage(...)` rather than `Get.toNamed(...)`
/// directly.
abstract class RouteManagement {
  static void goToProductsPage() {
    unawaited(Get.toNamed<dynamic>(AppRoutes.products));
  }

  static void goToProductDetailsPage(ProductDetailsPageArgument argument) {
    unawaited(
      Get.toNamed<dynamic>(AppRoutes.productDetails, arguments: argument),
    );
  }
}
