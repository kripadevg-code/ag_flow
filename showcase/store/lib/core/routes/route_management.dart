import 'package:ag_showcase_store/core/arguments/arguments.dart';

import 'app_pages.dart';
import 'app_routes.dart';

/// The only place the app navigates by route — every screen calls a
/// `goToXPage(...)` method here, never a literal path.
abstract class RouteManagement {
  static void goToProductsPage() {
    AppPages.router.pushNamed<void>(AppRoutes.product);
  }

  static void goToProductDetailsPage(ProductDetailsPageArgument argument) {
    AppPages.router.pushNamed<void>(
      AppRoutes.productDetails,
      pathParameters: argument.toPathParameters(),
    );
  }
}
