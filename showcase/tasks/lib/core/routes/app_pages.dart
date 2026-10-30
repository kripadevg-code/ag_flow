import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/auth/guards.dart';
import 'package:ag_showcase_tasks/modules/auth/bindings/auth_binding.dart';
import 'package:ag_showcase_tasks/modules/auth/pages/login_page.dart';
import 'package:ag_showcase_tasks/modules/auth/pages/register_page.dart';
import 'package:ag_showcase_tasks/modules/profile/bindings/profile_binding.dart';
import 'package:ag_showcase_tasks/modules/profile/pages/profile_page.dart';
import 'package:ag_showcase_tasks/modules/projects/bindings/project_details_binding.dart';
import 'package:ag_showcase_tasks/modules/projects/bindings/project_tasks_binding.dart';
import 'package:ag_showcase_tasks/modules/projects/bindings/projects_binding.dart';
import 'package:ag_showcase_tasks/modules/projects/pages/project_details_page.dart';
import 'package:ag_showcase_tasks/modules/projects/pages/project_tasks_page.dart';
import 'package:ag_showcase_tasks/modules/projects/pages/projects_page.dart';
import 'package:ag_showcase_tasks/modules/shell/pages/shell_page.dart';
import 'package:ag_showcase_tasks/modules/tasks/bindings/task_details_binding.dart';
import 'package:ag_showcase_tasks/modules/tasks/bindings/tasks_binding.dart';
import 'package:ag_showcase_tasks/modules/tasks/pages/task_details_page.dart';
import 'package:ag_showcase_tasks/modules/tasks/pages/tasks_page.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// All routes for the Tasks showcase app, on plain go_router — the app
/// owns its router; AG only supplies the module lifecycle ([AgRoutePage]).
///
/// Architecture highlights visible here:
///
///   1. [ShellRoute] — wraps the three main tabs in persistent bottom-nav
///      chrome ([ShellPage]). Switching tabs never rebuilds the shell, so
///      the bottom bar and its selected index survive every tab switch.
///      A shell that owns shared state would wrap its builder output in
///      [AgShellScope] to tie a binding to the shell's own lifetime.
///
///   2. [AgGuard] — [AuthGuard] protects every route inside the shell;
///      [GuestGuard] redirects already-authenticated users away from
///      login/register. Each runs from the route's `redirect` via
///      [AgGuard.check], so a blocked page is never built and its binding
///      is never registered.
///
///   3. Route path as navigation identity — the path constant in
///      [AppRoutes] is used everywhere: as the URL, as the route name, and
///      as the argument to `RouteManagement`'s `pushNamed`/`goNamed`
///      calls. One constant, one source of truth.
abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  /// Handed to `MaterialApp.router(routerConfig: AppPages.router)`.
  ///
  /// Starts on /login — [GuestGuard] forwards to /tasks when a session
  /// already exists (in a real app, hydrated from secure storage in
  /// `InitialBinding` before the first frame).
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: pages,
  );

  static final List<RouteBase> pages = [
    // ── Auth routes — outside the shell, no auth required ────────────────
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.login,
      redirect: (context, state) =>
          AgGuard.check(const [GuestGuard()], state.fullPath!),
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        binding: AuthBinding(),
        transition: AgTransition.fade,
        child: const LoginPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: AppRoutes.register,
      redirect: (context, state) =>
          AgGuard.check(const [GuestGuard()], state.fullPath!),
      pageBuilder: (context, state) => AgRoutePage<void>(
        key: state.pageKey,
        pathParameters: state.pathParameters,
        extra: state.extra,
        binding: AuthBinding(),
        transition: AgTransition.fade,
        child: const RegisterPage(),
      ),
    ),

    // ── Shell — hosts the bottom nav and the three tabs ───────────────────
    //
    // The shell's own widget (ShellPage) renders the bottom nav bar; `child`
    // is whichever route inside the shell is currently active. Navigation
    // between tabs never rebuilds the shell — the bottom bar and any
    // shell-level state survive tab switches.
    ShellRoute(
      builder: (context, state, child) =>
          ShellPage(location: state.uri.path, child: child),
      routes: [
        // Tab 1 — Tasks list + detail
        GoRoute(
          path: AppRoutes.tasks,
          name: AppRoutes.tasks,
          redirect: (context, state) =>
              AgGuard.check(const [AuthGuard()], state.fullPath!),
          pageBuilder: (context, state) => AgRoutePage<void>(
            key: state.pageKey,
            pathParameters: state.pathParameters,
            extra: state.extra,
            binding: TasksBinding(),
            transition: AgTransition.none,
            child: const TasksPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.taskDetails,
          name: AppRoutes.taskDetails,
          redirect: (context, state) =>
              AgGuard.check(const [AuthGuard()], state.fullPath!),
          pageBuilder: (context, state) => AgRoutePage<void>(
            key: state.pageKey,
            pathParameters: state.pathParameters,
            extra: state.extra,
            binding: TaskDetailsBinding(),
            transition: AppPages.defaultTransition,
            child: const TaskDetailsPage(),
          ),
        ),

        // Tab 2 — Projects list + detail + nested tasks
        GoRoute(
          path: AppRoutes.projects,
          name: AppRoutes.projects,
          redirect: (context, state) =>
              AgGuard.check(const [AuthGuard()], state.fullPath!),
          pageBuilder: (context, state) => AgRoutePage<void>(
            key: state.pageKey,
            pathParameters: state.pathParameters,
            extra: state.extra,
            binding: ProjectsBinding(),
            transition: AgTransition.none,
            child: const ProjectsPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.projectDetails,
          name: AppRoutes.projectDetails,
          redirect: (context, state) =>
              AgGuard.check(const [AuthGuard()], state.fullPath!),
          pageBuilder: (context, state) => AgRoutePage<void>(
            key: state.pageKey,
            pathParameters: state.pathParameters,
            extra: state.extra,
            binding: ProjectDetailsBinding(),
            transition: AppPages.defaultTransition,
            child: const ProjectDetailsPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.projectTasks,
          name: AppRoutes.projectTasks,
          redirect: (context, state) =>
              AgGuard.check(const [AuthGuard()], state.fullPath!),
          pageBuilder: (context, state) => AgRoutePage<void>(
            key: state.pageKey,
            pathParameters: state.pathParameters,
            extra: state.extra,
            binding: ProjectTasksBinding(),
            transition: AppPages.defaultTransition,
            child: const ProjectTasksPage(),
          ),
        ),

        // Tab 3 — Profile
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profile,
          redirect: (context, state) =>
              AgGuard.check(const [AuthGuard()], state.fullPath!),
          pageBuilder: (context, state) => AgRoutePage<void>(
            key: state.pageKey,
            pathParameters: state.pathParameters,
            extra: state.extra,
            binding: ProfileBinding(),
            transition: AgTransition.none,
            child: const ProfilePage(),
          ),
        ),
      ],
    ),
  ];
}
