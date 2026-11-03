import 'package:ag_flow_example/core/bindings/initial_binding.dart';
import 'package:ag_flow_example/core/routes/app_pages.dart';
import 'package:flutter/material.dart';

void main() {
  // App-wide singletons (ApiProvider, AuthService) must exist before the
  // router runs its first guard.
  InitialBinding().dependencies();
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
