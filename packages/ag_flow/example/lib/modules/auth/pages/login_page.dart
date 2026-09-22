import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/auth/auth_service.dart';
import 'package:ag_flow_example/core/routes/app_routes.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You are not logged in.\nPick a role to simulate login.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // AuthGuard unlocks /home after login
            FilledButton(
              onPressed: () {
                AuthService.instance.login();
                AgNavigator.offAllNamed(AppRoutes.home);
              },
              child: const Text('Login as User'),
            ),
            const SizedBox(height: 12),

            // RoleGuard(admin) unlocks /admin after this login
            FilledButton.tonal(
              onPressed: () {
                AuthService.instance.login(role: UserRole.admin);
                AgNavigator.offAllNamed(AppRoutes.home);
              },
              child: const Text('Login as Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
