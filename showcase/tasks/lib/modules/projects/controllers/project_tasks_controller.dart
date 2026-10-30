import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/tasks_repo.dart';

/// Nested tasks for a project — a detail-shaped module whose data is a
/// list, fetching a collection filtered by a parent argument.
class ProjectTasksController extends AgBaseController<List<Task>> {
  ProjectTasksController(this._repo)
    : argument = ProjectTasksPageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final ProjectTasksPageArgument argument;

  static ProjectTasksController get find =>
      AgLocator.find<ProjectTasksController>();

  final TasksRepo _repo;

  @override
  Future<List<Task>> fetch() async {
    // jsonplaceholder does not filter todos by post id, so we fetch all
    // and filter client-side — this is intentional for the demo.
    final tasks = await _repo.list();
    return tasks.where((t) => t.userId == argument.projectId % 10 + 1).toList();
  }
}
