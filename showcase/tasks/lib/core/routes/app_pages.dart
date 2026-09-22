// ignore_for_file: prefer_const_constructors
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

import 'app_routes.dart';

/// All routes for the Tasks showcase app.
///
/// Architecture highlights visible here:
///
///   1. [AgShellRoute] — wraps the three main tabs in persistent bottom-nav
///      chrome. The shell's binding is registered once on entry and
///      released on exit — it owns any state shared across all three tabs.
///
///   2. [AgGuard] — [AuthGuard] protects every route inside the shell.
///      [GuestGuard] redirects already-authenticated users away from login.
///      Guards run before the route is built so a blocked page's binding
///      is never registered.
///
///   3. Route path as navigation identity — the path constant in
///      [AppRoutes] is used everywhere: as the URL, as the route name, and
///      as the argument to [AgNavigator]. One constant, one source of truth.
abstract class AppPages {
  static const AgTransition defaultTransition = AgTransition.rightToLeft;

  static final List<AgRouteBase> pages = [
    // ── Auth routes — outside the shell, no auth required ────────────────
    AgRoute(
      path: AppRoutes.login,
      page: LoginPage.new,
      binding: AuthBinding(),
      guards: [const GuestGuard()],
      transition: AgTransition.fade,
    ),
    AgRoute(
      path: AppRoutes.register,
      page: RegisterPage.new,
      binding: AuthBinding(),
      guards: [const GuestGuard()],
      transition: AgTransition.fade,
    ),

    // ── Shell — hosts the bottom nav and the three tabs ───────────────────
    //
    // AgShellRoute wraps child routes in persistent chrome. The shell's own
    // Widget (ShellPage) renders the bottom nav bar; `child` is whichever
    // tab route is currently active. Navigation between tabs never rebuilds
    // the shell — scroll positions, animation state, and shell-level
    // controllers all survive tab switches.
    AgShellRoute(
      builder: (context, child) => ShellPage(child: child),
      routes: [
        // Tab 1 — Tasks list + detail
        AgRoute(
          path: AppRoutes.tasks,
          page: TasksPage.new,
          binding: TasksBinding(),
          guards: [const AuthGuard()],
          transition: AgTransition.none,
        ),
        AgRoute(
          path: AppRoutes.taskDetails,
          page: TaskDetailsPage.new,
          binding: TaskDetailsBinding(),
          guards: [const AuthGuard()],
          transition: defaultTransition,
        ),

        // Tab 2 — Projects list + detail + nested tasks
        AgRoute(
          path: AppRoutes.projects,
          page: ProjectsPage.new,
          binding: ProjectsBinding(),
          guards: [const AuthGuard()],
          transition: AgTransition.none,
        ),
        AgRoute(
          path: AppRoutes.projectDetails,
          page: ProjectDetailsPage.new,
          binding: ProjectDetailsBinding(),
          guards: [const AuthGuard()],
          transition: defaultTransition,
        ),
        AgRoute(
          path: AppRoutes.projectTasks,
          page: ProjectTasksPage.new,
          binding: ProjectTasksBinding(),
          guards: [const AuthGuard()],
          transition: defaultTransition,
        ),

        // Tab 3 — Profile
        AgRoute(
          path: AppRoutes.profile,
          page: ProfilePage.new,
          binding: ProfileBinding(),
          guards: [const AuthGuard()],
          transition: AgTransition.none,
        ),
      ],
    ),
  ];
}
