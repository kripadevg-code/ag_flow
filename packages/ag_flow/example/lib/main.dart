import 'package:ag_flow/ag_flow.dart';
import 'package:ag_flow_example/core/bindings/initial_binding.dart';
import 'package:ag_flow_example/core/routes/app_pages.dart';
import 'package:ag_flow_example/core/routes/app_routes.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AgFlowExampleApp());
}

class AgFlowExampleApp extends StatelessWidget {
  const AgFlowExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AgApp(
      title: 'ag_flow example',
      initialRoute: AppRoutes.product,
      initialBinding: InitialBinding(),
      routes: AppPages.pages,
    );
  }
}
