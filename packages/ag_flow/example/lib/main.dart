import 'package:ag_flow_example/core/auth/auth_service.dart';
import 'package:ag_flow_example/core/bindings/initial_binding.dart';
import 'package:ag_flow_example/core/routes/app_pages.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // App-wide singletons (ApiProvider, AuthService) must exist before the
  // router runs its first guard.
  InitialBinding().dependencies();
  // Reads the stored token once, so a saved session skips the login page.
  await AuthService.instance.restoreSession();
  runApp(const AgFlowExampleApp());
}

class AgFlowExampleApp extends StatelessWidget {
  const AgFlowExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ag_flow example',
      routerConfig: AppPages.router,
    );
  }
}
