import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';

import 'app_routes.dart';

/// The single place where navigation calls are made.
///
/// Every call is typed — a [TaskDetailsPageArgument] rather than a raw
/// string — so a mismatched argument type is a compile error, not a runtime
/// crash. Navigation methods live here, not scattered across pages.
abstract class RouteManagement {
  // Auth
  static void goToLoginPage() => AgNavigator.offAllNamed(AppRoutes.login);

  static void goToRegisterPage() => AgNavigator.toNamed(AppRoutes.register);

  // Shell tabs — use offAllNamed so the tab becomes the new root
  static void goToTasksPage() => AgNavigator.offAllNamed(AppRoutes.tasks);

  static void goToProjectsPage() => AgNavigator.offAllNamed(AppRoutes.projects);

  static void goToProfilePage() => AgNavigator.offAllNamed(AppRoutes.profile);

  // Tasks
  static void goToTaskDetailsPage(TaskDetailsPageArgument argument) =>
      AgNavigator.toNamed(
        AppRoutes.taskDetails,
        pathParameters: argument.toPathParameters(),
      );

  // Projects
  static void goToProjectDetailsPage(ProjectDetailsPageArgument argument) =>
      AgNavigator.toNamed(
        AppRoutes.projectDetails,
        pathParameters: argument.toPathParameters(),
      );

  static void goToProjectTasksPage(ProjectTasksPageArgument argument) =>
      AgNavigator.toNamed(
        AppRoutes.projectTasks,
        pathParameters: argument.toPathParameters(),
      );
}
