// AgRoute constructors use `.new` tear-offs for `page`, which are not const
// expressions — so the AgRoute instances can never be const themselves.
// ignore_for_file: prefer_const_constructors
import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/auth/auth_service.dart';
import 'package:ag_flow_example/core/auth/guards.dart';
import 'package:ag_flow_example/modules/admin/pages/admin_panel_page.dart';
import 'package:ag_flow_example/modules/auth/pages/login_page.dart';
import 'package:ag_flow_example/modules/home/pages/home_page.dart';
import 'package:ag_flow_example/modules/product/bindings/product_details_binding.dart';
import 'package:ag_flow_example/modules/product/bindings/products_binding.dart';
import 'package:ag_flow_example/modules/product/pages/product_details_page.dart';
import 'package:ag_flow_example/modules/product/pages/products_page.dart';

import 'app_routes.dart';

abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  static final List<AgRoute> pages = [
    // -------------------------------------------------------------------------
    // Auth routes
    // -------------------------------------------------------------------------

    // Use-case 2 — GuestGuard
    // Logged-in users who navigate to /login are silently redirected to
    // /home — they never see the login screen again.
    AgRoute(
      path: AppRoutes.login,
      page: LoginPage.new,
      guards: [const GuestGuard()],
      transition: AgTransition.fade,
    ),

    // Use-case 1 — AuthGuard
    // Only logged-in users can reach /home.  Everyone else lands on /login.
    AgRoute(
      path: AppRoutes.home,
      page: HomePage.new,
      guards: [const AuthGuard()],
      transition: AgTransition.fade,
    ),

    // Use-case 3 — AuthGuard + RoleGuard (multiple guards, left-to-right)
    // • Not logged in          → AuthGuard fires  → /login  (RoleGuard skipped)
    // • Logged in, not admin   → RoleGuard fires  → /home
    // • Logged in, admin       → both pass        → /admin
    AgRoute(
      path: AppRoutes.adminPanel,
      page: AdminPanelPage.new,
      guards: [const AuthGuard(), const RoleGuard(UserRole.admin)],
      transition: defaultTransition,
    ),

    // -------------------------------------------------------------------------
    // Feature routes — no guard, publicly accessible
    // -------------------------------------------------------------------------
    AgRoute(
      path: AppRoutes.product,
      page: ProductsPage.new,
      binding: ProductsBinding(),
      transition: defaultTransition,
    ),
    AgRoute(
      path: AppRoutes.productDetails,
      page: ProductDetailsPage.new,
      binding: ProductDetailsBinding(),
      transition: defaultTransition,
    ),
  ];
}
