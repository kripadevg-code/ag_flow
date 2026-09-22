/// Every route path in one place.
///
/// One constant per route — the same string is used as:
///   • the go_router path (registered in AppPages)
///   • the navigation argument (called from RouteManagement)
///   • the route name (go_router uses path as name in AG)
///
/// Never pass a string literal to AgNavigator. Always use a constant here.
abstract class AppRoutes {
  // ── Shell wrapper (hosts the bottom nav) ─────────────────────────────
  static const String shell = '/';

  // ── Tab 1 — Tasks ─────────────────────────────────────────────────────
  static const String tasks   = '/tasks';
  static const String taskDetails = '/tasks/:id';

  // ── Tab 2 — Projects ──────────────────────────────────────────────────
  static const String projects        = '/projects';
  static const String projectDetails  = '/projects/:id';
  static const String projectTasks    = '/projects/:id/tasks';

  // ── Tab 3 — Profile ───────────────────────────────────────────────────
  static const String profile = '/profile';

  // ── Auth (outside the shell) ──────────────────────────────────────────
  static const String login    = '/login';
  static const String register = '/register';
}
