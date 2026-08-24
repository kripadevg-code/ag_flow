import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_blog/core/bindings/initial_binding.dart';
import 'package:ag_showcase_blog/core/routes/app_pages.dart';
import 'package:ag_showcase_blog/core/routes/app_routes.dart';
import 'package:flutter/material.dart';

void main() => runApp(const BlogShowcaseApp());

class BlogShowcaseApp extends StatelessWidget {
  const BlogShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AgApp(
      title: 'AG Showcase — Blog',
      initialRoute: AppRoutes.post,
      initialBinding: InitialBinding(),
      routes: AppPages.pages,
    );
  }
}
