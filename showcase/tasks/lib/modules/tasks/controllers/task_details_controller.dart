import 'package:ag_flow/ag_flow.dart';
import 'package:ag_showcase_tasks/core/arguments/arguments.dart';
import 'package:ag_showcase_tasks/modules/tasks/models/task.dart';
import 'package:ag_showcase_tasks/modules/tasks/repos/task_details_repo.dart';

/// Detail controller for a single task.
///
/// The navigation argument is rebuilt from the route's path parameters, so
/// the page opens correctly from a deep link, a push notification, or an
/// in-app tap. [update] is optimistic: it shows the change at once and
/// rolls back if the write fails.
class TaskDetailsController extends AgBaseController<Task>
    with AgRetrieve<Task> {
  TaskDetailsController(this._repo)
    : argument = TaskDetailsPageArgument.fromPathParameters(
        AgRouteData.pathParameters,
      );

  final TaskDetailsRepo _repo;

  final TaskDetailsPageArgument argument;

  static TaskDetailsController get find =>
      AgLocator.find<TaskDetailsController>();

  int get lookupId => argument.taskId;

  @override
  Future<Task> retrieve() => _repo.retrieve(lookupId);

  /// Optimistic: shows [item] at once and rolls back if the write fails.
  Future<void> update(Task item) async {
    final current = state.dataOrNull;
    emit(AgPageState.success(item));
    try {
      emit(AgPageState.success(await _repo.update(lookupId, item)));
    } on Object {
      if (current != null) emit(AgPageState.success(current)); // roll back
    }
  }

  Future<void> toggleCompleted() async {
    final current = state.dataOrNull;
    if (current == null) return;
    await update(current.copyWith(completed: !current.completed));
  }
}
