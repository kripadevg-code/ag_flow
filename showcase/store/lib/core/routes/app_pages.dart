import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/modules/product/bindings/product_details_binding.dart';
import 'package:ag_showcase_store/modules/product/bindings/products_binding.dart';
import 'package:ag_showcase_store/modules/product/pages/product_details_page.dart';
import 'package:ag_showcase_store/modules/product/pages/products_page.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Every route in the app, on plain go_router — the app owns the router
/// and its go_router version.
abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  /// Hand this to `MaterialApp.router(routerConfig: AppPages.router)`.
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.product,
    routes: pages,
  );

  static final List<RouteBase> pages = [
    GoRoute(
      path: AppRoutes.product,
      name: AppRoutes.product,
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        binding: ProductsBinding(),
        transition: AppPages.defaultTransition,
        child: const ProductsPage(),
      ),
    ),

    GoRoute(
      path: AppRoutes.productDetails,
      name: AppRoutes.productDetails,
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        binding: ProductDetailsBinding(),
        transition: AppPages.defaultTransition,
        child: const ProductDetailsPage(),
      ),
    ),
  ];
}
