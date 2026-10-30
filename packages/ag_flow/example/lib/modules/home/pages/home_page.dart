import 'package:ag_flow_example/core/auth/auth_service.dart';
import 'package:ag_flow_example/core/routes/route_management.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          TextButton(
            onPressed: () {
              authService.logout();
              // AuthGuard on /home will redirect to /login automatically.
              RouteManagement.resetToHomePage();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Logged in as: ${authService.role.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),

            // No guard — always accessible
            const OutlinedButton(
              onPressed: RouteManagement.goToProductsPage,
              child: Text('Go to Products (no guard)'),
            ),
            const SizedBox(height: 12),

            // AuthGuard + RoleGuard(admin):
            //   • as user  → allowed by AuthGuard, blocked by RoleGuard → stays on /home
            //   • as admin → both guards pass → reaches /admin
            const OutlinedButton(
              onPressed: RouteManagement.goToAdminPanelPage,
              child: Text('Go to Admin Panel (role guard)'),
            ),
            const SizedBox(height: 12),

            // GuestGuard on /login redirects back to /home
            const OutlinedButton(
              onPressed: RouteManagement.goToLoginPage,
              child: Text('Try to visit /login (guest guard)'),
            ),
          ],
        ),
      ),
    );
  }
}
