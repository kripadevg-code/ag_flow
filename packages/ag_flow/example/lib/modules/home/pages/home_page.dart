import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/auth/auth_service.dart';
import 'package:ag_flow_example/core/routes/app_routes.dart';
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
              AgNavigator.offAllNamed(AppRoutes.home);
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
            OutlinedButton(
              onPressed: () => AgNavigator.toNamed<dynamic>(AppRoutes.product),
              child: const Text('Go to Products (no guard)'),
            ),
            const SizedBox(height: 12),

            // AuthGuard + RoleGuard(admin):
            //   • as user  → allowed by AuthGuard, blocked by RoleGuard → stays on /home
            //   • as admin → both guards pass → reaches /admin
            OutlinedButton(
              onPressed: () =>
                  AgNavigator.toNamed<dynamic>(AppRoutes.adminPanel),
              child: const Text('Go to Admin Panel (role guard)'),
            ),
            const SizedBox(height: 12),

            // GuestGuard on /login redirects back to /home
            OutlinedButton(
              onPressed: () => AgNavigator.toNamed<dynamic>(AppRoutes.login),
              child: const Text('Try to visit /login (guest guard)'),
            ),
          ],
        ),
      ),
    );
  }
}
