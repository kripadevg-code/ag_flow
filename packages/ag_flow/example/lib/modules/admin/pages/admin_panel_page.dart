import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/routes/app_routes.dart';
import 'package:flutter/material.dart';

/// Admin panel — only reachable when the user is logged in AND has the
/// [UserRole.admin] role.  Two guards protect this route:
///
///   guards: [AuthGuard(), RoleGuard(UserRole.admin)]
///
/// Guard order matters:
///   1. AuthGuard runs first.  If not logged in → redirect to /login.
///      RoleGuard never runs.
///   2. RoleGuard runs second.  If logged in but role != admin → redirect
///      to /home.
///   3. Both pass → this page is shown.
class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings, size: 64),
            const SizedBox(height: 16),
            const Text('You have admin access.'),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => AgNavigator.back<dynamic>(),
              child: const Text('Back'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => AgNavigator.toNamed<dynamic>(AppRoutes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
