import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/bindings/initial_binding.dart';
import 'package:ag_showcase_tasks/core/routes/app_pages.dart';
import 'package:ag_showcase_tasks/core/routes/app_routes.dart';
import 'package:flutter/material.dart';

void main() => runApp(const TasksShowcaseApp());

/// AG Tasks — architecture reference app for ag_flow.
///
/// Demonstrates every major framework feature in one cohesive, real app:
///
///   AgShellRoute      — persistent bottom-nav shell (tasks / projects / profile)
///   AgGuard           — AuthGuard protects every tab, GuestGuard blocks /login
///   AgStateService    — AuthService holds session state, readable anywhere
///   AgCrudService     — full CRUD on Tasks and Projects
///   AgPagedService    — paginated list loading (AgListController, AgListBuilder)
///   AgDetailController — deep-linkable detail pages with path parameters
///   updateItems       — optimistic mutations without a round-trip refresh
///   AgBuilder         — lightweight reactive rebuild for the Profile screen
///
/// Backend: jsonplaceholder.typicode.com (public demo API — no auth needed).
/// Auth is simulated client-side to demonstrate the guard flow.
class TasksShowcaseApp extends StatelessWidget {
  const TasksShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AgApp(
      title: 'AG Tasks',
      // Start on /login — GuestGuard will redirect to /tasks if a real app
      // had a stored session token.
      initialRoute: AppRoutes.login,
      initialBinding: InitialBinding(),
      routes: AppPages.pages,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6EF5),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6EF5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
