import 'package:ag_showcase_tasks/core/arguments/arguments.dart';

import 'app_pages.dart';
import 'app_routes.dart';

/// The single place where navigation calls are made.
///
/// Every call is typed — a [TaskDetailsPageArgument] rather than a raw
/// string — so a mismatched argument type is a compile error, not a runtime
/// crash. Navigation methods live here, not scattered across pages, and
/// every one goes through the app's own `AppPages.router`.
abstract class RouteManagement {
  // Auth
  static void goToLoginPage() => AppPages.router.goNamed(AppRoutes.login);

  static void goToRegisterPage() {
    AppPages.router.pushNamed<void>(AppRoutes.register);
  }

  // Shell tabs — `goNamed` so the tab becomes the new root (and the URL).
  static void goToTasksPage() => AppPages.router.goNamed(AppRoutes.tasks);

  static void goToProjectsPage() => AppPages.router.goNamed(AppRoutes.projects);

  static void goToProfilePage() => AppPages.router.goNamed(AppRoutes.profile);

  // Tasks
  static void goToTaskDetailsPage(TaskDetailsPageArgument argument) {
    AppPages.router.pushNamed<void>(
      AppRoutes.taskDetails,
      pathParameters: argument.toPathParameters(),
    );
  }

  // Projects
  static void goToProjectDetailsPage(ProjectDetailsPageArgument argument) {
    AppPages.router.pushNamed<void>(
      AppRoutes.projectDetails,
      pathParameters: argument.toPathParameters(),
    );
  }

  static void goToProjectTasksPage(ProjectTasksPageArgument argument) {
    AppPages.router.pushNamed<void>(
      AppRoutes.projectTasks,
      pathParameters: argument.toPathParameters(),
    );
  }

  /// Pops the current route, if there is one to pop.
  static void back<T extends Object?>([T? result]) {
    if (AppPages.router.canPop()) AppPages.router.pop<T>(result);
  }
}
