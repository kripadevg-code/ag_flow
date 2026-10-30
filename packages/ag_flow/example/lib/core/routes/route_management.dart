import 'package:ag_flow_example/core/arguments/arguments.dart';

import 'app_pages.dart';
import 'app_routes.dart';

/// The only place the app navigates by route — every screen calls a
/// method here, never a literal path.
abstract class RouteManagement {
  // Auth
  static void goToLoginPage() {
    AppPages.router.pushNamed<void>(AppRoutes.login);
  }

  static void goToHomePage() {
    AppPages.router.pushNamed<void>(AppRoutes.home);
  }

  /// Clears the stack and lands on /home — its guards decide where the
  /// user actually ends up (AuthGuard sends a logged-out user to /login).
  static void resetToHomePage() {
    AppPages.router.goNamed(AppRoutes.home);
  }

  static void goToAdminPanelPage() {
    AppPages.router.pushNamed<void>(AppRoutes.adminPanel);
  }

  // Products
  static void goToProductsPage() {
    AppPages.router.pushNamed<void>(AppRoutes.product);
  }

  static void goToProductDetailsPage(ProductDetailsPageArgument argument) {
    AppPages.router.pushNamed<void>(
      AppRoutes.productDetails,
      pathParameters: argument.toPathParameters(),
    );
  }

  // Generic
  static void back<T extends Object?>([T? result]) {
    if (AppPages.router.canPop()) AppPages.router.pop<T>(result);
  }
}
