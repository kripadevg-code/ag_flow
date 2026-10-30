// Copied into a freshly generated app by generator-integration.yaml and run
// there — it is the only test that drives *generated* code at runtime:
// binding registration through the generated GoRoute + AgRoutePage, the
// generated RouteManagement, the detail controller's lookupId from the URL,
// and teardown on pop. Lives under .github/ so the workspace analyzer,
// which can't resolve `generator_smoke_app`, never sees it.
import 'package:ag_flow/ag_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:generator_smoke_app/core/arguments/arguments.dart';
import 'package:generator_smoke_app/core/bindings/initial_binding.dart';
import 'package:generator_smoke_app/core/routes/app_pages.dart';
import 'package:generator_smoke_app/core/routes/app_routes.dart';
import 'package:generator_smoke_app/core/routes/route_management.dart';
import 'package:generator_smoke_app/modules/order/controllers/orders_controller.dart';
import 'package:generator_smoke_app/modules/product/controllers/product_details_controller.dart';
import 'package:generator_smoke_app/modules/product/controllers/products_controller.dart';

void main() {
  testWidgets('generated modules route, bind, look up and tear down', (
    tester,
  ) async {
    InitialBinding().dependencies();
    await tester.pumpWidget(MaterialApp.router(routerConfig: AppPages.router));
    await tester.pumpAndSettle();

    // `ag init` leaves AppRoutes.initial at '/', which no module claims —
    // a real app points it at its first screen; this does the same.
    AppPages.router.go(AppRoutes.product);
    await tester.pumpAndSettle();
    expect(AgLocator.find<ProductsController>(), isNotNull);

    RouteManagement.goToProductDetailsPage(
      const ProductDetailsPageArgument(id: '5'),
    );
    await tester.pumpAndSettle();
    expect(AgLocator.find<ProductDetailsController>().lookupId, '5');
    expect(
      AppPages.router.state.uri.toString(),
      AppRoutes.productDetails.replaceFirst(':id', '5'),
    );

    AppPages.router.pop();
    await tester.pumpAndSettle();
    expect(AgLocator.find<ProductDetailsController>, throwsStateError);
    expect(AgLocator.find<ProductsController>(), isNotNull);

    // A typed, trimmed module (--from-json, --methods=add).
    RouteManagement.goToOrdersPage();
    await tester.pumpAndSettle();
    expect(AgLocator.find<OrdersController>(), isNotNull);
  });
}
