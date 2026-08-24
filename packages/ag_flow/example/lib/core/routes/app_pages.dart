import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/modules/product/bindings/product_details_binding.dart';
import 'package:ag_flow_example/modules/product/bindings/products_binding.dart';
import 'package:ag_flow_example/modules/product/pages/product_details_page.dart';
import 'package:ag_flow_example/modules/product/pages/products_page.dart';

import 'app_routes.dart';

abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  static final List<AgRoute> pages = [
    AgRoute(
      name: AppRoutes.product,
      page: ProductsPage.new,
      binding: ProductsBinding(),
      transition: AppPages.defaultTransition,
    ),

    AgRoute(
      name: AppRoutes.productDetails,
      page: ProductDetailsPage.new,
      binding: ProductDetailsBinding(),
      transition: AppPages.defaultTransition,
    ),
  ];
}
