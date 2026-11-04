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
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Every route in the app, on plain go_router — the app owns the router.
abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  /// Hand this to `MaterialApp.router(routerConfig: AppPages.router)`.
  ///
  /// Starts on /login.
  /// • Not logged in → LoginPage shown (GuestGuard passes through).
  /// • Already logged in (e.g. after hot restart with a persisted session)
  ///   → GuestGuard on /login fires and redirects to /home automatically.
  ///
  /// `refreshListenable` re-runs every guard when the login state changes, so
  /// logging in or out needs no navigation call.
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: AuthService.instance,
    routes: pages,
  );

  /// Sends a logged-out user to /login.
  static AgAuthGuard get _session => AgAuthGuard(AuthService.instance, loginPath: AppRoutes.login);

  static final List<RouteBase> pages = [
    // -------------------------------------------------------------------------
    // Auth routes
    // -------------------------------------------------------------------------

    // Use-case 2 — GuestGuard
    // Logged-in users who navigate to /login are silently redirected to
    // /home — they never see the login screen again.
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.login,
      redirect: (context, state) => AgGuard.check(const [GuestGuard()], state.fullPath!),
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        transition: AgTransition.fade,
        child: LoginPage(key: state.pageKey),
      ),
    ),

    // Use-case 1 — AgAuthGuard
    // Only logged-in users can reach /home.  Everyone else lands on /login.
    GoRoute(
      path: AppRoutes.home,
      name: AppRoutes.home,
      redirect: (context, state) => AgGuard.check([_session], state.fullPath!),
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        transition: AgTransition.fade,
        child: HomePage(key: state.pageKey),
      ),
    ),

    // Use-case 3 — AgAuthGuard + RoleGuard (multiple guards, left-to-right)
    // • Not logged in          → AgAuthGuard fires  → /login  (RoleGuard skipped)
    // • Logged in, not admin   → RoleGuard fires  → /home
    // • Logged in, admin       → both pass        → /admin
    GoRoute(
      path: AppRoutes.adminPanel,
      name: AppRoutes.adminPanel,
      redirect: (context, state) => AgGuard.check(
        [_session, const RoleGuard(UserRole.admin)],
        state.fullPath!,
      ),
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        transition: AppPages.defaultTransition,
        child: AdminPanelPage(key: state.pageKey),
      ),
    ),

    // -------------------------------------------------------------------------
    // Feature routes — no guard, publicly accessible
    // -------------------------------------------------------------------------
    GoRoute(
      path: AppRoutes.product,
      name: AppRoutes.product,
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        binding: ProductsBinding(),
        transition: AppPages.defaultTransition,
        child: ProductsPage(key: state.pageKey),
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
        child: ProductDetailsPage(key: state.pageKey),
      ),
    ),
  ];
}
