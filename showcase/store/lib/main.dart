import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_store/core/bindings/initial_binding.dart';
import 'package:ag_showcase_store/core/routes/app_pages.dart';
import 'package:ag_showcase_store/core/routes/app_routes.dart';
import 'package:flutter/material.dart';

void main() => runApp(const StoreShowcaseApp());

class StoreShowcaseApp extends StatelessWidget {
  const StoreShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AgApp(
      title: 'AG Showcase — Store',
      initialRoute: AppRoutes.product,
      initialBinding: InitialBinding(),
      routes: AppPages.pages,
    );
  }
}
