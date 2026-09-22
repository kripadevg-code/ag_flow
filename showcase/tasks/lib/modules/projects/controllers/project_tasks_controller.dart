import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/tasks_repo.dart';

/// Nested tasks for a project — a detail-shaped module whose data is a
/// list. Demonstrates [AgDetailController] used as the base for a module
/// that fetches a collection filtered by a parent argument.
class ProjectTasksController
    extends AgDetailController<List<Task>, ProjectTasksPageArgument> {
  ProjectTasksController(this._repo);

  static ProjectTasksController get find =>
      AgLocator.find<ProjectTasksController>();

  final TasksRepo _repo;

  @override
  ProjectTasksPageArgument? argumentsFromPath(
    Map<String, String> pathParameters,
  ) => ProjectTasksPageArgument.fromPathParameters(pathParameters);

  @override
  Future<List<Task>> fetch() async {
    // jsonplaceholder does not filter todos by post id, so we fetch all
    // and filter client-side — this is intentional for the demo.
    final page = await _repo.getPage(0);
    return page.items
        .where((t) => t.userId == arguments.projectId % 10 + 1)
        .toList();
  }
}
