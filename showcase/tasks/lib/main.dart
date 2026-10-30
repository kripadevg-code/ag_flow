import 'package:ag_showcase_tasks/core/bindings/initial_binding.dart';
import 'package:ag_showcase_tasks/core/routes/app_pages.dart';
import 'package:flutter/material.dart';

void main() {
  // App-wide singletons (ApiProvider, AuthService) — registered before the
  // first frame so the initial route's guard can already read AuthService.
  InitialBinding().dependencies();
  runApp(const TasksShowcaseApp());
}

/// AG Tasks — architecture reference app for ag_flow.
///
/// Demonstrates every major framework feature in one cohesive, real app:
///
///   GoRouter + AgRoutePage — the app owns its go_router; AgRoutePage ties
///                         each module's AgBinding to its route's lifetime
///   ShellRoute         — persistent bottom-nav shell (tasks / projects / profile)
///   AgGuard            — AuthGuard protects every tab, GuestGuard blocks /login
///   AgStateService     — AuthService holds session state, readable anywhere
///   Service mixins     — AgCreateMixin / AgRetrieveMixin / AgUpdateMixin /
///                         AgDestroyMixin as typed contracts the Services
///                         implement, with AgPagedService for paging
///   Plain Repos        — one per module, delegating to its Service
///   AgListController   — paging, plus writes made optimistic via updateItems
///   AgDetailController — deep-linkable detail pages (argument from the path
///                         parameters), including an optimistic toggle and a
///                         detail page whose data is a filtered list
///   AgBuilder          — lightweight reactive rebuild for the Profile screen
///
/// Backend: jsonplaceholder.typicode.com (public demo API — no auth needed).
/// Auth is simulated client-side to demonstrate the guard flow.
class TasksShowcaseApp extends StatelessWidget {
  const TasksShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AG Tasks',
      // The router starts on /login — GuestGuard will redirect to /tasks if
      // a real app had a stored session token.
      routerConfig: AppPages.router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B6EF5)),
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
