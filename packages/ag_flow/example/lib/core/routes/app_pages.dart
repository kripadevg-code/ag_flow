import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/routes/app_routes.dart';
import 'package:ag_flow_example/product/bindings/product_details_binding.dart';
import 'package:ag_flow_example/product/bindings/products_binding.dart';
import 'package:ag_flow_example/product/pages/product_details_page.dart';
import 'package:ag_flow_example/product/pages/products_page.dart';

/// Every generated route's `GetPage` registration (see
/// requirments/routes.md §7).
abstract class AppPages {
  static const Transition defaultTransition = Transition.rightToLeft;

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.products,
      page: ProductsPage.new,
      binding: ProductsBinding(),
      transition: defaultTransition,
    ),
    GetPage(
      name: AppRoutes.productDetails,
      page: ProductDetailsPage.new,
      binding: ProductDetailsBinding(),
      transition: defaultTransition,
    ),
  ];
}
