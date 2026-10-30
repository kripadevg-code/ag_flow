import 'package:ag_showcase_blog/core/bindings/initial_binding.dart';
import 'package:ag_showcase_blog/core/routes/app_pages.dart';
import 'package:flutter/material.dart';

void main() {
  InitialBinding().dependencies();
  runApp(const BlogShowcaseApp());
}

class BlogShowcaseApp extends StatelessWidget {
  const BlogShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AG Showcase — Blog',
      routerConfig: AppPages.router,
    );
  }
}
