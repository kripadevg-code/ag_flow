import 'package:ag_showcase_store/core/bindings/initial_binding.dart';
import 'package:ag_showcase_store/core/routes/app_pages.dart';
import 'package:flutter/material.dart';

void main() {
  InitialBinding().dependencies();
  runApp(const StoreShowcaseApp());
}

class StoreShowcaseApp extends StatelessWidget {
  const StoreShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AG Showcase — Store',
      routerConfig: AppPages.router,
    );
  }
}
